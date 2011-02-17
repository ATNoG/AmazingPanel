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
          @params = args
          @meta = args[:meta] 
          unless @meta.nil? 
            duration = @meta[:properties][:duration]
            @testbed = @meta[:properties][:testbed]
            if duration.nil?
              duration = 30
              @meta[:properties] = {:duration => duration}
            else
              duration = duration.to_i
              @meta[:properties][:duration] = duration
            end
            @duration = duration
          end
        end

        def createApplicationDefinition(args)
          uri = args[0]
          name = args[1]
          properties = args[2]
          blockApp = s(:block, nil)
          block_index = 1

          properties[:options].each do |k,v|
            if k != "properties"
              # attributes
              if k == "version"
                v_values = v.split(".")
                sexp = s(:call, 
                    s(:lvar, :app), 
                    :version, 
                    s(:arglist, 
                      s(:lit, v_values[0].to_i), 
                      s(:lit, v_values[1].to_i),
                      s(:lit, v_values[2].to_i)))
              else
                sexp = s(:attrasgn, 
                    s(:lvar, :app), 
                    "#{k}=".to_sym, 
                    s(:arglist, 
                      s(:str, v)))
              end
              blockApp[block_index] = sexp
              block_index += 1
            else
              # properties
              v.each do |prop,prop_v|
                options = s(:hash, nil)
                h_i = 1
                prop_v[:options].each do |opt,opt_v|
                  options[h_i] = s(:lit, opt)
                  options[h_i + 1] = s(:str, opt_v)
                  h_i += 2
                end
                sexp = s(:call,               
                  s(:lvar, :app),
                  :defProperty,
                  s(:arglist, 
                    s(:str, k), 
                    s(:str, prop_v[:description].to_s), 
                    s(:str, prop_v[:mnemonic]), 
                    options))
                blockApp[block_index] = sexp
                block_index += 1
              end
            end
          end

          # measurements
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
          
          iterApp = s(:lasgn, :app)
          iterVar = s(:lvar, :app)
          defApplication = s(:iter, 
            s(:call,               
              nil,
              :defApplication, 
              s(:arglist, 
                s(:str, uri.to_s), 
                s(:str, name.to_s))),
            iterApp, blockApp)
          return defApplication
        end

        # Generates --
        # defGroup(name)        
        def createGroup(name, props, auto=false)
          application = props[:applications]["0"]
          nodes = props[:nodes]
          properties = props[:properties]

          iterNode = s(:lasgn, :node)
          iterApp = s(:lasgn, :app)
          blockApp = s(:block)          
          i = 1
          application[:options][:properties].each do |k,v|
            app_setProp = s(:call, 
              s(:lvar, :app), 
              :setProperty, 
              s(:arglist, 
                s(:str, k), 
                s(:lit, v)))
            blockApp[i] = app_setProp
            i += 1
          end
          application[:measures][:selected].each do |m|
            app_setProp = s(:call, 
              s(:lvar, :app), 
              :measure, 
              s(:arglist, 
                s(:str, m), 
                s(:hash, 
                  s(:lit, :samples), 
                  s(:lit, 1))))

            blockApp[i] = app_setProp
            i += 1
          end
          addApplication = s(:iter, 
            s(:call, 
              s(:lvar, :node), 
              :addApplication, 
              s(:arglist, s(:str, application[:uri].to_s))), 
            iterApp, 
            blockApp
          )

          group_block = s(:block, addApplication)
          unless auto
            group_block = groupProperties(group_block, properties)            
          end
          defGroup = s(:call, 
            nil, 
            :defGroup.to_sym, 
            s(:arglist, s(:str, name.to_s), s(:str, nodes.join(","))))
          defGroup_block = s(:iter, 
            defGroup, 
            iterNode, 
            group_block)
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
              s(:lit, @duration)))
          expDone = s(:call, 
            s(:const, :Experiment), 
            :done, 
            s(:arglist))
          onEvent = s(:call, 
            nil, 
            :onEvent, 
            s(:arglist, 
              s(:lit, :APP_UP_AND_INSTALLED)))
          iterNode = s(:lasgn, :node)
          all_up_block = s(:iter, onEvent, iterNode, timeline)
          return all_up_block
        end

        def from_sexp(method, args)
          return Ruby2Ruby.new().process(self.send(method, args))
        end

        def to_rb()
        end

        def to_s()          
          code = ""
          ruby2ruby = Ruby2Ruby.new()
          # generate groups
          auto = false
          if @meta[:properties][:network] == "on"
            auto = true
          end
          @meta[:groups].each do |index, group|
            puts "#{index} => #{group.inspect}"
            if !group[:applications].nil?
              ruby_group = createGroup(group[:name], group, auto)
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
        def timeline()
          if @params[:timeline].nil?
            return s(:block, startApplications, expDuration, stopApplications, expDone)
          end
          timeline = @params[:timeline]
          blockTimeline = s(:block, nil)
          n = timeline.size
          to_start = timeline.sort { |x,y| x[:start] <=> y[:start]  }
          to_stop = timeline.sort { |x,y| x[:stop] <=> y[:stop]  }
          tm = to_start[0]
          i = 1
          waitStatement = Proc.new {|t| s(:call, nil, :wait, s(:arglist, s(:lit, t))) }
          groupStart = Proc.new {|g| s(:call, s(:call, nil, :group, s(:arglist, s(:str, g))), :startApplications, s(:arglist)) }
          groupStart = Proc.new {|g| s(:call, s(:call, nil, :group, s(:arglist, s(:str, g))), :stopApplications, s(:arglist)) }
          while (to_start.size > 0 and to_stop.size > 0) do
            tm = (to_start[0][:start] <= to_stop[0][:stop]) ? to_start[0] : to_stop[0]
            blockTimeline[i] = waitStatement.call(tm[:start])
            i += 1
            blockTimeline[i] = groupStart.call(tm[:group])
            i += 1
            if (to_start[0][:start] <= to_stop[0][:stop])
              to_start.delete_at(0)
            else
              to_stop.delete_at(0)
            end
          end
          return blockTimeline
        end
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
        
        def groupProperties(sblock, properties)
          if properties[:net].nil?
            return sblock;
          end
          start = 2
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
