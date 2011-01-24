module OMF
  module Experiments
    module OEDL

      class OEDLParser < RubyParser
        attr_accessor :apps

        def initialize(ed)
          super()
          @raw = process(ed)
          @apps = Array.new
        end

        def getApplicationMetrics()
          @apps = @apps.clear()
          getApplications()
          getMetrics()
          ret = Array.new()
          @apps.each do |app|
            ret.push({:app => app[:name], :metrics => app[:metrics]})
          end
          return ret
        end

        def getApplications()
          @raw.each_of_type(:iter) do |i|
            app = i[1]
            if (app[2] == :addApplication)
              app = { :sexp => app, :locals => app[1], :name => app[3][1][1].split(":"), :block => i[3], :metrics => Array.new() }
              if @apps.index(app).nil? 
                @apps.push(app)
              end
            end
          end
        end

        def getDuration        
        end

        def getSenderGroups
        end

        def defReceiverGroups
        end

        def getMetrics()
          @apps.each do |app|
            app[:block].each_of_type(:call) do |call|
              if (call[2] == :measure)
                app[:metrics].push({:name => call[3][1][1]})
              end
            end
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
      
      def defGroup(name, selector=nil, &block)
        if @properties[:groups] != Hash
          @properties[:groups] = Hash.new()
        end
        @properties[:groups][name] = {:selector => selector}
        block.call(Node.new(self, name))
        pp self
      end      
      
      def defEvent(name, interval = 5, &block)
      end
      
      def onEvent(name, consumeEvent = false, &block)
      end

    end
  end
end
