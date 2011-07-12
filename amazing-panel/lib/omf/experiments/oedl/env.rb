module OMF::Experiments::OEDL
    
    module Environment

      
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
      
      class OEDLPrototypeApplication < Prototype
        def initialize(ref, proto, uri)
          super(ref)
          @proto = proto
          @uri = uri
        end

        def bindProperty(uri, name)          
          @ref.properties[:proto][@proto][:applications][@uri][:bind][uri] = name
        end
        
        def setProperty(name, value)
          @ref.properties[:proto][@proto][:applications][@uri][:properties][name] = value
        end
        
        def measure(mp, options={})
          @ref.properties[:proto][@proto][:applications][@uri][:measures][mp] = options
        end
      end
      
      class OEDLPrototype < Prototype
        attr_accessor :name, :description

        def initialize(ref, name, description=nil)
          super(ref)
          @name = name
          @description = description
          ref.properties[:proto][name] = { 
            :applications => {}, 
          }
          @ref = ref
        end
        
        def addApplication(uri, name=nil, &block)
          @ref.properties[:proto][@name][:applications][uri] = { 
            :name => name,
            :properties => {},
            :bind => {},
            :measures => {}
          }

          if block
            block.call(OEDLPrototypeApplication.new(@ref, @name, uri))
          end
        end
      end

      class OEDLNode < Prototype
        attr_accessor :net
        
        def initialize(ref, name)
          super(ref)
          @net = self
          @group = name
          ref.properties[:groups][name][:node] = { 
            :applications => {}, 
            :net => {}
          }
          @ref = ref
        end

        def w0() interface(:w0) end
        def w1() interface(:w1) end
        def e0() interface(:e0) end
        def e1() interface(:e1) end

        def prototype(uri, properties={})
        end

        def addApplication(id, opts={}, &block)
          block.call(Application.new(@ref, id, @group))
        end
        
        protected
        def interface(name)
          tmp = @ref.properties[:groups][@group][:node]
          if tmp[:net][name].nil?
            tmp[:net][name] = Interface.new()
          end
          return @ref.properties[:groups][@group][:node][:net][name]
        end
      end

      class ApplicationDefinition < Prototype
        #attr_accessor :uri, :name, :path, :version, :shortDescription, :description, :omlPrefix, :measurements

        def initialize(ref, uri, name)
          @ref = ref
          @uri = uri
          ref.properties[:repository][:apps][@uri] = { 
            :name => name, 
            :properties => {}
          }
          ref.properties[:repository][:apps][@uri] = { 
            :name => name, 
            :properties => {}, 
            :measures => {}
          }
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
      
      def defProperty(name, default, description=nil)
        @properties[:properties][name] = { 
          :default => default, 
          :description => description
        }
      end

      def property()        
        # Inline property access for Experiment: property.*
        # due to the properties access of general context
        def self.method_missing(name, args = nil)
          return @properties[:properties][name.to_s][:default]
        end
        return self
      end

      alias :prop :property
      
      def defPrototype(name, description=nil, &block)
        @properties[:proto][name] = {}
        block.call(OEDLPrototype.new(self, name, description))
      end 

      def defGroup(name, selector=nil, &block)
        @properties[:groups][name] = { :selector => selector }
        block.call(OEDLNode.new(self, name))
      end

      def defEvent(name, interval = 5, &block)
      end
      
      def onEvent(name, consumeEvent = false, &block)
      end

      def defApplication(uri, appName, &block)
        block.call(ApplicationDefinition.new(self, uri, appName))        
      end      
    end

end

