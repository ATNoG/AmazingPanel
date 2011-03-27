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
      BLACKLIST = [ ".", "..",
        "itgdec.rb",
        "gennySenderAppDef.rb",
        "gennyReceiverAppDef.rb",
        "nop.rb",
        "appDef1.rb",
        "itgr.rb",
        "itgs.rb",
        "aodvd.rb",
        "athstats.rb",
        "otg2_mp.rb", 
        "otr2_mp.rb", 
        "nop.rb", 
        "wlanconfig_oml2.rb",
        "echo.rb"
      ]

      WHITELIST = [
        "iperf", 
        "otg2", 
        "otr2", 
        "trace_oml2"
      ]

      def self.exec(exp_id, ed)
        script = OMF::Workspace.open_ed(ed.user, "#{ed.id.to_s}.rb")
        file = OMF::Workspace.ed_for(ed.user, "#{ed.id.to_s}.rb")
        c = Context.new(exp_id)
        eval(script, c.getBinding(), file)
        return c 
      end

      def self.getDefinition(uri_or_path, code=nil)
        c = Context.new(-1)
        if code.nil?
          r_path = uri_or_path
          if uri_or_path.index(':')
            r_path = "#{APP_CONFIG['oedl_repository']}/#{uri_or_path.gsub(/[:]/,'/')}.rb"
          end
          code = IO::read(r_path)
          eval(code, c.getBinding(), r_path)
        else
          eval(code, c.getBinding())
        end
        return c
      end

      def self.scanRepositories()
        repo_app_path = Dir.new("#{APP_CONFIG['oedl_repository']}/test/app")
        files = repo_app_path.entries.delete_if { |x| BLACKLIST.include?(x) }
        apps = Hash.new()
        files.each do |f|
          c = getDefinition("#{repo_app_path.path}/#{f}")
          apps.merge!(c.properties[:repository][:apps])
        end
        return apps
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
require 'omf/experiments/ec'
