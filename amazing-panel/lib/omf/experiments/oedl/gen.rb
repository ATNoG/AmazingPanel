require File.dirname(__FILE__) + "/gen/helpers.rb"

module OMF::Experiments::OEDL
     
    class Generator
        include GeneratorHelpers
        include GeneratorValidations
        attr_accessor :meta

        def initialize(args = {})
          unless args.empty?
            @params = args[:meta]
            @meta = @params[:meta]
            @repository = args[:repository] unless args[:repository].nil?
            @groups = []
            unless @meta.nil?
              @duration = @meta[:properties][:duration] || 30
              @testbed = @meta[:properties][:testbed]
              @meta[:properties][:duration] = @duration.to_i
            end
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
              begin
                # attributes
                if k == "version"
                  v_values = v.split(".")
                  sexp = version(v_values)
                else
                  sexp = attr_assgn(k, v)
                end
                blockApp[block_index] = sexp
                block_index += 1
              rescue
                next
              end
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
                blockApp[block_index] = defProperty(prop, description, mnemonic, options)
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
                blockMetrics[bMetrics_index] = defMetric(name, type)             
                bMetrics_index += 1
              end
              blockApp[block_index] = defMeasurement(ms, blockMetrics)
              block_index += 1
            end
          end
          
          return defApplication(app_uri, app_name, blockApp)
        end

        # Generates --
        # defGroup(name) { <> }      
        def createGroup(name, props, auto=false)
          applications = props[:applications].blank? ? nil : props[:applications]
          nodes = props[:nodes]
          properties = props[:properties]          

          group_block = s(:block, nil)
          group_block_index = 1

          if (auto or properties.blank?) and applications.blank?            
            return defGroup(name, nodes)
          end

          unless applications.blank?
            applications.each do |index,application|              
              if application[:options].blank? and application[:measures].blank?
                next
              end
              
              blockApp = s(:block, nil)                      
              i = 1
              
              unless application[:options].nil?
                  definition = @repository[application[:uri]]
                  application[:options][:properties].each do |k,v|
                    app_setProp = property(k, get_property_value(v, k, definition))
                    blockApp[i] = app_setProp.deep_clone
                    i += 1
                  end
              end
    
              unless application[:measures].nil?
                application[:measures][:selected].each do |m|
                  app_setProp = measure(m) 
                  blockApp[i] = app_setProp.deep_clone
                  i += 1
                end
              end
              
              group_block[group_block_index] = addApplication(application[:uri].to_s, blockApp.deep_clone)
              group_block_index += 1
            end
          end
  
          group_block = groupProperties(group_block, group_block_index, properties) unless auto
          return defGroup(name, nodes, group_block)
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
          onEvent_block = @params[:timeline].nil? ? s(:block, startApplications, expDuration(@duration),
                            stopApplications, experimentDone) : timeline()
          all_up_block = s(:iter,
              onEvent,
              s(:lasgn, :node),
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

          @groups = @meta[:groups].values
          @groups.delete_if {|x| !valid_group(x) }

          pp @groups

          @groups.each do |group|
            ruby_group = createGroup(group[:name], group, auto)
            ruby2ruby = Ruby2Ruby.new()
            code += ruby2ruby.process(ruby_group)+"\n"          
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
        # Helper method to generate a sequence of wait's
        #   representing the Timeline
        def timeline()
          timeline = @params[:timeline]
          blockTimeline = s(:block, nil)
          n = timeline.size

          only_exec_evts = timeline.reject { |x| x[:stop] == -1 }.size() == 0                    
          timeline.push(timeline_event("__all__", 0, @duration)) if only_exec_evts
          
          to_stop = timeline.sort { |x,y| x[:stop] <=> y[:stop]  }
          to_stop.delete_if { |x| x[:stop] == -1 }          
          to_start = timeline.sort { |x,y| x[:start] <=> y[:start]  }
          
          tm = empty_init_object
          timeline_tm = 0
          i = 1

          while (to_start.size > 0 or to_stop.size > 0) do
            prev_tm = tm
            tm = timeline_get_tm(tm, to_start, to_stop)
            wait_time = tm[:tm] - prev_tm[:tm]
            i -= 1
            blockTimeline[i+=1] = waitStatement(wait_time) if wait_time.to_i > 0
            if tm[:action] == "start"
              blockTimeline[i+1] = groupStart(tm[:group])
            elsif tm[:action] == "stop"
              blockTimeline[i+1] = groupStop(tm[:group])
            elsif tm[:action] == "command"
              blockTimeline[i+1] = groupExec({:group => tm[:group], :command => tm[:command]})
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
            tm = start_tm_object(start[:group], start[:start]) 
            if start[:command]
              tm[:command] = start[:command]
              tm[:action] = "command"
            end
            to_start.delete_at(0)
          elsif is_stop # is stop
            tm = stop_tm_object(stop[:group], stop[:stop]) 
            to_stop.delete_at(0)
          end
          return tm
        end

        def empty_init_object()
          tm_object("",0,"start")
        end

        def start_tm_object(group, tm)          
          tm_object(group, tm, "start")
        end
        
        def stop_tm_object(group, tm)
          tm_object(group, tm, "stop")
        end

        def tm_object(group, tm, action)
          { :action => action, :tm => tm.to_i, :group => group }
        end

        def timeline_event(group, start, stop, command=nil)
          ret = {:group => group, :start => start.to_i, :stop => stop.to_i }
          ret[:command] = command unless command.nil?
          ret
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
              sblock[start] = node_property(k, pkey, pvalue)
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
end
