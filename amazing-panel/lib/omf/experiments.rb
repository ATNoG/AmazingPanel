require 'ruby_parser'
require 'pp'
require 'omf/experiments/oedl'

module OMF
  module Experiments  
    class Context      
      include OMF::Experiments::OEDL
      attr_accessor :id, :properties
      def initialize(id)
        @id = id
        @properties = {}
      end

      def getBinding
        return binding
      end
    end
    
    module ScriptHandler
      def self.exec(exp_id, ed)
        script = OMF::Workspace.open_ed(ed.user, "#{ed.id.to_s}.rb")
        file = OMF::Workspace.ed_for(ed.user, "#{ed.id.to_s}.rb")
        c = Context.new(exp_id)
        #pp c 
        eval(script, c.getBinding(), file)
        return c 
      end
    end

    # Get the appropiate results for the experiment
    def self.results(experiment,args)
      ed = experiment.ed
      ed_content = OMF::Workspace.open_ed(ed.user, "#{ed.id.to_s}.rb")
      #parser = OMF::Experiments::OEDLParser.new(ed_content)
      script = OMF::Experiments::ScriptHandler.exec(experiment.id, ed)
      # Iterate over groups
      app_metrics = Array.new()
      script.properties[:groups].each do |group,v|
        apps = v[:node][:applications]
        metrics = Array.new();
        pp apps
        apps.each do |app, properties|
          properties[:metrics].each do |name, options|
            metrics.push({:name => name})
          end          
          app_metrics.push({:app => app, :metrics => metrics });
        end
      end      
      data = OMF::Experiments::GenericResults.new(experiment, args)
      return { :metrics => app_metrics, :results => data }
    end
  end
end

require 'omf/experiments/results'
#require 'omf/experiments/ec'
require 'omf/experiments/proxy'
