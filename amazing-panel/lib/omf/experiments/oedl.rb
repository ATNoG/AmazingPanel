require File.dirname(__FILE__) + "/../../../app/models/node"
require 'ruby_parser'
require 'ruby2ruby'
require 'pp'

module OMF
  module Experiments
    module OEDL
      class Script
        attr_accessor :meta
        
        def initialize(args = {})
          @params = args[:meta]
          @meta = @params[:meta]
          @repository = args[:repository] unless args[:repository].nil?
          
          unless @meta.nil? 
            duration = @meta[:properties][:duration]
            @testbed = @meta[:properties][:testbed]
            if duration.nil?
              @duration = 30
            end
            @meta[:properties][:duration] = duration.to_i
            @duration = duration
          end
        end

        # Generates an application definition
        def createApplicationDefinition(args)
          app_uri = args[0]
          app_name = args[1]

          properties = args[2]
          blockApp = s(:block, nil)
          block_index = 1

          properties[:options].each do |k,v|
            if k != "properties"
              # attributes
              if k == "version"
                v_values = v.split(".")
                sexp = version(v_values)
              else
                sexp = attr_assgn(k, v)
              end
              blockApp[block_index] = sexp
              block_index += 1
            else
              # properties
              v.each do |prop,prop_v|
                options = s(:hash, nil)
                h_i = 1
                prop_v[:options].each do |opt,opt_v|
                  options[h_i] = s(:lit, opt.to_sym)
                  v = nil
                  is_sym_value = (opt == "dynamic" or opt == "type")
                  is_int_value = (opt == "order")
                  need_bool_sexp = (opt == "dynamic")
                  need_lit_sexp = (opt == "type" or opt == "order")
                  v = opt_v.to_sym if is_sym_value
                  v = opt_v.to_i if is_int_value
                  options[h_i + 1] = s(v) if need_bool_sexp
                  options[h_i + 1] = s(:lit, v) if need_lit_sexp
                  h_i += 2
                end
                #options = s(:block, options)
                mnemonic = s_str(prop_v[:mnemonic])
                description = s_str(prop_v[:description].to_s)
                sexp = s(:call,               
                  s(:lvar, :app),
                  :defProperty,
                  s(:arglist, 
                    s(:str, prop), 
                    description,
                    mnemonic, 
                    options))
                blockApp[block_index] = sexp
                block_index += 1
              end
            end
          end

          # measurements
          unless properties[:measures].nil?
            properties[:measures].each do |ms, fields|
              blockMetrics = s(:block, nil)
              bMetrics_index = 1
              fields.each do |name, type|
                blockMetrics[bMetrics_index] = s(:call, 
                    s(:lvar, :mp), 
                    :defMetric, 
                    s(:arglist, 
                      s(:str, name.to_s), 
                      s(:lit, type.to_sym)))
                bMetrics_index += 1
              end
              blockMeasurements = s(:iter, 
                  s(:call, 
                    s(:lvar, :app), 
                    :defMeasurement, 
                    s(:arglist, 
                      s(:str,  ms))), 
                    s(:lasgn, :mp), blockMetrics)
              blockApp[block_index] = blockMeasurements
              block_index += 1
            end
          end
          
          iterApp = s(:lasgn, :app)
          iterVar = s(:lvar, :app)
          defApplication = s(:iter, 
            s(:call,               
              nil,
              :defApplication, 
              s(:arglist, 
                s(:str, app_uri.to_s), 
                s(:str, app_name.to_s))),
            iterApp, blockApp)
          return defApplication
        end

        # Generates --
        # defGroup(name) { <> }      
        def createGroup(name, props, auto=false)
          applications = props[:applications].blank? ? nil : props[:applications]
          nodes = props[:nodes]
          properties = props[:properties]          

          iterNode = s(:lasgn, :node)
          iterApp = s(:lasgn, :app)
          group_block = s(:block, nil)
          group_block_index = 1

          unless applications.nil?
            applications.each do |index,application|              
              blockApp = s(:block, nil)                      
              i = 1
              unless application[:options].nil?
                  definition = @repository[application[:uri]]
                  application[:options][:properties].each do |k,v|
                    app_setProp = s(:call, 
                      s(:lvar, :app), 
                      :setProperty, 
                      s(:arglist, 
                        s(:str, k), 
                        get_property_value(v, k, definition)))
                    blockApp[i] = app_setProp.deep_clone
                    i += 1
                  end
              end
  
              unless application[:measures].nil?
                application[:measures][:selected].each do |m|
                  app_setProp = s(:call, 
                    s(:lvar, :app), 
                    :measure, 
                    s(:arglist, 
                      s(:str, m), 
                      s(:hash, 
                        s(:lit, :samples), 
                        s(:lit, 1))))
    
                  blockApp[i] = app_setProp.deep_clone
                  i += 1
                end
              end
              
              group_block[group_block_index] = s(:iter, 
                s(:call, 
                  s(:lvar, :node), 
                  :addApplication, 
                  s(:arglist, s(:str, application[:uri].to_s))), 
                s(:lasgn, :app), blockApp.deep_clone)
              group_block_index += 1
            end
          end         
          unless auto
            group_block = groupProperties(group_block, group_block_index, properties)            
          end
          defGroup = s(:call, 
            nil, 
            :defGroup.to_sym, 
            s(:arglist, s(:str, name.to_s), s(:str, nodes.join(","))))
          defGroup_block = s(:iter, defGroup, s(:lasgn, :node), group_block)
          
          return defGroup_block
        end
        
        # Generates --
        #  onEvent(:ALL_UP_AND_INSTALLED) do |node|
        #   info "This is my first OMF experiment"
        #   wait 10
        #   allGroups.startApplications
        #   info "All my Applications are started now..."
        #   wait 5
        #   allGroups.stopApplications
        #   info "All my Applications are stopped now."
        #   Experiment.done
        #  end
        def all_up()
          startApplications = s(:call,  
            s(:call, 
              nil, 
              :allGroups, 
              s(:arglist)), 
            :startApplications, 
            s(:arglist))
          stopApplications = s(:call, 
            s(:call, 
              nil, 
              :allGroups, 
              s(:arglist)), 
            :stopApplications, 
            s(:arglist))
          expDuration = s(:call, 
            nil, 
            :wait, 
            s(:arglist, 
              s(:lit, @duration.to_i)))
          onEvent = s(:call, 
            nil, 
            :onEvent, 
            s(:arglist, 
              s(:lit, :APP_UP_AND_INSTALLED)))
          iterNode = s(:lasgn, :node)
          onEvent_block = @params[:timeline].nil? ? s(:block, startApplications, expDuration, 
                            stopApplications, experimentDone) : timeline()
          all_up_block = s(:iter, 
              onEvent, 
              iterNode, 
              onEvent_block)
          return all_up_block
        end

        def from_sexp(method, args)
          return Ruby2Ruby.new().process(self.send(method, args))
        end

        def to_rb()
        end

        def to_s()          
          code = ""
          # generate groups
          auto = false          
          if @meta[:properties][:network] == "on"
            auto = true
          end

          @meta[:groups].each do |index, group|
            Rails.logger.debug "#{index} => #{group.inspect}"
            unless group[:applications].blank? and group[:properties].blank?
              ruby_group = createGroup(group[:name], group, auto)
              ruby2ruby = Ruby2Ruby.new()
              code += ruby2ruby.process(ruby_group)+"\n"
            end
          end 
          # generate ALL_UP event
          ruby2ruby = Ruby2Ruby.new()          
          if auto
            code += ruby2ruby.process(s(:block, autoNetworkProperties, all_up()))
          else
            code += ruby2ruby.process(s(:block, all_up()))
          end

          return code
        end

        protected

        # Helper method to generate: "some_string" or nil (symbol)
        def s_str(value=nil)
          if value.nil? or value.size == 0
            return s(:nil)
          else
            return s(:str, value.to_s)
          end
        end
        
        # Helper method to generate: version(x, y, z)
        def version(v_values)
          return s(:call, 
                    s(:lvar, :app), 
                    :version, 
                    s(:arglist, 
                      s(:lit, v_values[0].to_i), 
                      s(:lit, v_values[1].to_i),
                      s(:lit, v_values[2].to_i)))
        end

        # Helper method to generate the attributes assignment in a Application Definition
        def attr_assgn(attribute, value)
          return s(:attrasgn, 
                    s(:lvar, :app), 
                    "#{attribute}=".to_sym, 
                    s(:arglist, 
                      s(:str, value)))
        end

        # Helper to generate the value from its definition type
        def get_property_value(value, property, definition)
          default = s(:str, value)
          if definition.nil? then return default end
          
          property = definition[:properties][property]
          options = property[:options]
          
          if options.nil? then return default end
          
          type = options[:type]
          if type.nil? then return default end
          
          case
          when type == :integer
            return s(:lit, value.to_i)
          when type == :boolean
            return s(value.to_sym)
          when type == :string
            return s(:str, value.to_s)
          end
          return default          
        end

        # Helper method to generate: Experiment.done
        def experimentDone()
          expDone = s(:call, 
            s(:const, :Experiment), 
            :done, 
            s(:arglist))
          return expDone
        end

        # Helper method to generate a sequence of wait's
        #   representing the Timeline
        def timeline()
          timeline = @params[:timeline]
          blockTimeline = s(:block, nil)
          n = timeline.size
          to_start = timeline.sort { |x,y| x[:start] <=> y[:start]  }
          to_stop = timeline.sort { |x,y| x[:stop] <=> y[:stop]  }
          to_stop.delete_if { |x| x[:stop] == -1 }
          tm = { :group => "", :tm => 0, :action => "start" }
          timeline_tm = 0
          i = 1
          waitStatement = Proc.new {|t| s(:call, nil, :wait, s(:arglist, s(:lit, t))) }
          groupExec = Proc.new { |g|
            s(:call, 
              s(:call, nil, :group, 
                s(:arglist, 
                  s(:str, g[:group]))), 
              :exec, 
              s(:arglist, 
                s(:str, g[:command]))) 
          }
          groupStart = Proc.new { |g| 
            s(:call, 
              s(:call, nil, :group, 
                s(:arglist, 
                  s(:str, g))), 
              :startApplications, 
              s(:arglist)) 
          }
          groupStop = Proc.new { |g| 
            s(:call, 
              s(:call, nil, :group, 
                s(:arglist, 
                  s(:str, g))), 
              :stopApplications, 
              s(:arglist)) 
          }          
          while (to_start.size > 0 or to_stop.size > 0) do
            prev_tm = tm            
            tm = timeline_get_tm(tm, to_start, to_stop)
            blockTimeline[i] = waitStatement.call(tm[:tm] - prev_tm[:tm]) 
            if tm[:action] == "start"
              blockTimeline[i+1] = groupStart.call(tm[:group])
            elsif tm[:action] == "stop"
              blockTimeline[i+1] = groupStop.call(tm[:group])
            elsif tm[:action] == "command"
              blockTimeline[i+1] = groupExec.call({:group => tm[:group], :command => tm[:command]})
            end           
            i += 2
          end
          blockTimeline[i] = experimentDone()
          return blockTimeline
        end

        # Comparing two timestamps, returns the early one
        def timeline_get_tm(tm, to_start, to_stop)
          start = to_start[0]; stop = to_stop[0]
          if stop.nil?
            stop = to_start[0]
            stop[:stop] = start[:start] + 1
          end

          is_start = (!start.nil? and start[:start] <= stop[:stop])
          is_stop = (!stop.nil?)

          if is_start # is start
            tm = { :action => "start", :tm => start[:start], :group => start[:group] } 
            if start[:command]
              tm[:command] = start[:command]
              tm[:action] = "command"
            end
            to_start.delete_at(0)
          elsif is_stop # is stop
            tm = { :action => "stop", :tm => stop[:stop], :group => stop[:group] }
            to_stop.delete_at(0)
          end
          return tm
        end
       
        # Generate the auto configuring network properties
        def autoNetworkProperties()
          return s(:iter, 
            s(:call, 
              s(:call, 
                s(:call, 
                  nil, 
                  :allGroups, 
                  s(:arglist)), 
                :net, 
                s(:arglist)), 
              :w0, 
              s(:arglist)), 
            s(:lasgn, :interface), 
            s(:block, 
              s(:attrasgn, 
                s(:lvar, :interface), 
                :mode=, 
                s(:arglist, 
                  s(:str, "ad-hoc"))), 
              s(:attrasgn, 
                s(:lvar, :interface), 
                :type=, 
                s(:arglist, s(:str, "g"))),
              s(:attrasgn, 
                s(:lvar, :interface), 
                :channel=, 
                s(:arglist, s(:str, "6"))),
              s(:attrasgn, 
                s(:lvar, :interface), 
                :essid=, 
                s(:arglist, 
                  s(:str, "test"))),
              s(:attrasgn, 
                s(:lvar, :interface), 
                :ip=, 
                s(:arglist, 
                  s(:str, "192.168.0.%index")))))
        end
       
        # Giving a sblock, an index and some properties, generates
        # the network properties. e.g:
        # net.w0.ip = "192.168.2.1"
        def groupProperties(sblock, index, properties)
          if properties[:net].nil?
            return sblock;
          end
          start = index
          properties[:net].each do |k,v|
            v.each do |pkey, pvalue|
              next if (pvalue.size == 0)
              sblock[start] = s(:attrasgn, 
                s(:call, 
                  s(:call, 
                    s(:lvar, :node), 
                    :net, 
                    s(:arglist)), 
                  k.to_s,
                  s(:arglist)), 
                pkey.to_s, 
                s(:arglist, s(:str, pvalue)));
              start += 1;
            end
          end
          return sblock;
        end
        
        private        
        TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].to_set
        FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].to_set        

        def to_bool(value)
          if value.is_a?(String) && value.blank?
            nil
          else
            TRUE_VALUES.include?(value)
          end
        end
      end      

      class Experiment
      end
      
      class Interface
        attr_accessor :mode, :channel, :essid, :type, :ip, :rts, :rate,
                      :tx_power, :mac, :mtu, :arp, :enforce_link, :route,
                      :filter
      end
      
      class Prototype 
        def initialize(ref, name=nil)
          @ref = ref
        end
      
        def defProperty(id, property, description=nil)
        end
      end
      
      class Application < Prototype
        def initialize(ref, name, group)
          super(ref)
          @group = group
          @name = name.split(':').last
          ref.properties[:groups][group][:node][:applications] ||= Hash.new()          
          ref.properties[:groups][group][:node][:applications][@name] = {
            :omf_name => name,
            :properties => Hash.new(), 
            :metrics => Hash.new()
          }
          @ref = ref
        end
      
        def setProperty(name, value)
          @ref.properties[:groups][@group][:node][:applications][@name][:properties][name] = value
        end
      
        def measure(metric, options={})
          @ref.properties[:groups][@group][:node][:applications][@name][:metrics][metric] = options
        end
      end
      
      class OEDLNode < Prototype
        attr_accessor :net
        def initialize(ref, name)
          super(ref)
          @net = self
          @group = name
          ref.properties[:groups][name][:node] = { :applications => Hash.new(), :net => Hash.new()}
          @ref = ref
        end
      
        def w0()
          tmp = @ref.properties[:groups][@group][:node]
          if tmp[:net][:w0].nil?
            tmp[:net][:w0] = Interface.new()      
          end
          return @ref.properties[:groups][@group][:node][:net][:w0]
        end
      
        def addApplication(id, opts={}, &block)
          block.call(Application.new(@ref, id, @group))
        end
      end

      class ApplicationDefinition < Prototype
        #attr_accessor :uri, :name, :path, :version, :shortDescription, :description, :omlPrefix, :measurements

        def initialize(ref, uri, name)
          @ref = ref
          @uri = uri 
          ref.properties[:repository][:apps][@uri] = { :name => name, :properties => Hash.new }
          ref.properties[:repository][:apps][@uri] = { :name => name, :properties => Hash.new, :measures => Hash.new }
          @ref = ref
        end

        def method_missing(method_name, *args, &block)
          method_name = method_name.to_s.gsub(/[=]/,'')
          @ref.properties[:repository][:apps][@uri][method_name] = args[0]
        end

        def defProperty(name, description, mnemonic = nil, options = nil)
          @ref.properties[:repository][:apps][@uri][:properties][name] = { 
              :description => description, 
              :mnemonic => mnemonic,
              :options => options
          }
        end        

        def defMeasurement(name, &block)
          @current_measure = name
          @ref.properties[:repository][:apps][@uri][:measures][@current_measure] = {}
          block.call(self) 
        end

        def defMetric(name, type)
          @ref.properties[:repository][:apps][@uri][:measures][@current_measure][name] = {            
            :type => type
          }
        end

        def version(a,b,c)
          @version = "#{a}.#{b}.#{c}"
        end
      end

      def defGroup(name, selector=nil, &block)
        if @properties[:groups].class != Hash
          @properties[:groups] = Hash.new()
        end
        @properties[:groups][name] = {:selector => selector}
        block.call(OEDLNode.new(self, name))
      end      
      
      def defEvent(name, interval = 5, &block)
      end
      
      def onEvent(name, consumeEvent = false, &block)
      end

      def defApplication(uri, appName, &block)
        if @properties[:repository].class != Hash
          @properties[:repository] = Hash.new()
          @properties[:repository][:apps] = Hash.new()
        end
        block.call(ApplicationDefinition.new(self, uri, appName))        
      end
    end
  end
end
