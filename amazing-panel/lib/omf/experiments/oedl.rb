module OMF
  module Experiments
    module OEDL
      class OEDLScript
        attr_accessor :meta
        
        def initialize(args)
          @meta = args
          unless @meta.has_key?(:duration)
            @meta[:duration] = 30
          end
        end
        
        # Generates --
        # defGroup(name)        
        def createGroup(name)
          return s(:block, s(:call, nil, "defGroup".to_sym, s(:arglist, s(:str, name.to_s))))
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
          startApplications = s(:call,  s(:call, nil, :allGroups, s(:arglist)), :startApplications, s(:arglist))
          stopApplications = s(:call, s(:call, nil, :allGroups, s(:arglist)),:stopApplications, s(:arglist))
          expDuration = s(:call, nil, :wait, s(:arglist, s(:lit, @meta[:duration])))
          expDone = s(:call, s(:const, :Experiment), :done, s(:arglist))
          onEvent = s(:call, nil, :onEvent, s(:arglist, s(:lit, :APP_UP_AND_INSTALLED)))
          iterNode = s(:lasgn, :node)
          all_up_block = s(:iter, onEvent, iterNode, s(:block, startApplications, expDuration, stopApplications, expDone))
          return all_up_block
        end
        
        def toRuby()          
          require 'ruby_parser'
          require 'ruby2ruby'
          require 'pp'
          code = ""
          ruby2ruby = Ruby2Ruby.new()
          pp @meta
          # generate groups
          @meta[:groups].each do |group|
            code += ruby2ruby.process(createGroup(group))
          end 
          # generate ALL_UP event
          ruby2ruby = Ruby2Ruby.new()
          code += ruby2ruby.process(all_up())
          return code
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
      
      class Node < Prototype
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
        attr_accessor :uri, :name, :path, :version, :shortDescription, :description, :omlPrefix, :measurements

        def initialize(ref, uri, name)
          @ref = ref
          @uri = uri 
          ref.properties[:repository][:apps][@uri] = { :name => name, :properties => Hash.new }
          ref.properties[:repository][:apps][@uri] = { :name => name, :properties => Hash.new, :measures => Hash.new }
          @ref = ref
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
          block.call(self) 
        end

        def defMetric(name, type)
          @ref.properties[:repository][:apps][@uri][:measures][@current_measure] = {
            :name => name,
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
        block.call(Node.new(self, name))
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
