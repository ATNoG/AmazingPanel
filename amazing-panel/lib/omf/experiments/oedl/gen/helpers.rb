module OMF::Experiments::OEDL
  module GeneratorHelpers
    
    # generate: allGroups.startApplications
    def startApplications
       return s(:call,
         s(:call,
           nil,
           :allGroups,
           s(:arglist)),
         :startApplications,
         s(:arglist))
     end
     
    # generate: allGroups.stopApplications
     def stopApplications
       return s(:call,
         s(:call,
           nil,
           :allGroups,
           s(:arglist)),
         :stopApplications,
         s(:arglist))
     end

    # generate: wait #{duration}
     def expDuration(duration)
       return s(:call,
         nil,
         :wait,
         s(:arglist,
           s(:lit, duration.to_i)))
     end

    # generate: Experiment.done
     def experimentDone()
       expDone = s(:call,
         s(:const, :Experiment),
         :done,
         s(:arglist))
       return expDone
     end

     # generate: <auto configuring network properties>
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
     
     # generate: version(x, y, z)
     def version(v_values)
       return s(:call,
                 s(:lvar, :app),
                 :version,
                 s(:arglist,
                   s(:lit, v_values[0].to_i),
                   s(:lit, v_values[1].to_i),
                   s(:lit, v_values[2].to_i)))
     end

     # generate: addApplication(<uri>) do |app| <block> end
     def addApplication(uri, block)
      return s(:iter, 
                s(:call, 
                  s(:lvar, :node), 
                  :addApplication, 
                  s(:arglist, s(:str, uri))), 
                s(:lasgn, :app), block)
     end
    
     def defGroup(name, nodes, block=nil)
       header = s(:call,
            nil,
            :defGroup.to_sym,
            s(:arglist, s(:str, name.to_s), s(:str, nodes.join(","))))       
       if block
         return s(:iter, header, s(:lasgn, :node), block)
       else
         return header
       end
     end

     def defApplication(uri, name, block)    
       return s(:iter, 
         s(:call,               
           nil,
           :defApplication, 
           s(:arglist, 
             s(:str, uri.to_s), 
             s(:str, name.to_s))),
         s(:lasgn, :app), block)
     end

     def defProperty(name, description, mnemonic, options)
       return s(:call,               
                s(:lvar, :app),
                :defProperty,
                s(:arglist, 
                  s(:str, name), 
                  description,
                  mnemonic, 
                  options))

     end

     def defMeasurement(ms, block)
        return s(:iter, 
                  s(:call, 
                    s(:lvar, :app), 
                    :defMeasurement, 
                    s(:arglist, 
                      s(:str,  ms))), 
                    s(:lasgn, :mp), block)
     end

     def defMetric(name, type)
       return s(:call, 
                s(:lvar, :mp), 
                :defMetric, 
                s(:arglist, 
                  s(:str, name.to_s), 
                  s(:lit, type.to_sym)))
     end

     # generate: onEvent(:APP_UP_AND_INSTALLED)
     def onEvent
       return s(:call,
              nil,
              :onEvent,
              s(:arglist,
                s(:lit, :ALL_UP_AND_INSTALLED)))
     end

     # generate: group(#{name}).exec({command})
     def groupExec(g)     
       return s(:call,
              s(:call, nil, :group,
                s(:arglist,
                  s(:str, g[:group]))),
              :exec,
              s(:arglist,
                s(:str, g[:command])))          
    end
    
    # generate: group(#{name}).startApplications()
    def groupStart(g)
      unless g == "__all__"
        return s(:call,
                s(:call, nil, :group,
                  s(:arglist,
                    s(:str, g))),
                :startApplications,
                s(:arglist))          
      end
      return startApplications
    end
    
    # generate: group(#{name}).stopApplications()
    def groupStop(g)          
      unless g == "__all__"
        return s(:call,
                s(:call, nil, :group,
                  s(:arglist,
                    s(:str, g))),
                :stopApplications,
                s(:arglist))                
      end
      return stopApplications
    end

    # generate: wait #{timestamp}
    def waitStatement(t)      
      return s(:call, nil, :wait, s(:arglist, s(:lit, t.to_i)))
    end
    
    # generate: "some_string" or nil (symbol)
    def s_str(value=nil)
      if value.nil? or value.size == 0
        return s(:nil)
      else
        return s(:str, value.to_s)
      end
    end
   
    # 
    def property(key, value)
      return s(:call, 
          s(:lvar, :app), 
          :setProperty, 
          s(:arglist, 
            s(:str, key), 
            value))
    end

    def measure(metric, samples=1)
      return s(:call, 
          s(:lvar, :app), 
          :measure, 
          s(:arglist, 
            s(:str, metric), 
            s(:hash, 
              s(:lit, :samples), 
              s(:lit, samples))))

    end

    def node_property(eth, key, value)
      return s(:attrasgn,
                s(:call,
                  s(:call,
                    s(:lvar, :node),
                    :net,
                    s(:arglist)),
                  eth.to_s,
                  s(:arglist)),
                key.to_s,
                s(:arglist, s(:str, value)));
    end
    
    # generate: app.#{attribute} = value
    def attr_assgn(attribute, value)
      return s(:attrasgn,
                s(:lvar, :app),
                "#{attribute}=".to_sym,
                s(:arglist,
                  s(:str, value)))
    end

    # generate: <boolean>, <integer>, <string>
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

  end
end
