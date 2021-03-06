require 'ruby_parser'
require 'pp'

module OMF
  module Experiments
  end
end

require 'omf/experiments/oedl'

module OMF::Experiments
    class Context
      include OMF::Experiments::OEDL::Environment
      attr_accessor :id, :properties
      
      def initialize(id)
        @id = id
        @properties = {
            :groups => {}, 
            :proto => {}, 
            :topo => {}, 
            :repository => { 
                :apps => {}, 
                :topo => {}  
            }, 
            :properties => {}
        }
      end

      def getBinding
        return binding
      end
    end

    module ScriptHandler
      APP_CONFIG = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
      APPS_REPOSITORY = "#{APP_CONFIG['oedl_repository']}/test/app"
      BLACKLIST = [
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
      ].to_set

      WHITELIST = [
        "iperf", 
        "otg2", 
        "otr2", 
        "trace_oml2"
      ].to_set

      def self.exec_raw(code)
        c = Context.new(-1)
        eval(code, c.getBinding())
        return c
      end

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

      def self.writeDefinition(uri, code, appFile)
				name = uri
        unless code.nil? or uri.nil?
          if uri.index(':')
						name = uri.gsub(/[:]/,'/')
					end	

					# Write application definition
          r_path = Pathname.new("#{APP_CONFIG['oedl_repository']}/#{name}.rb")            
					FileUtils.mkdir_p(r_path.parent)
          File.open(r_path, 'w') do |file|
            file.write(code)
          end

					if appFile.nil?
						return true
					end

					# Write tar package
          tar_path = Pathname.new("#{APP_CONFIG['oedl_repository']}/#{name}.tar")            
          File.open(tar_path, 'w') do |file|
            file.write(appFile.read)
          end
          return true
        
				end
        return false
      end

      def self.removeDefinition(uri)
        path = Pathname.new("#{APP_CONFIG['oedl_repository']}/#{uri.gsub(/[:]/,'/')}.rb")
        begin
          FileUtils.remove_file(path)
          return true
        rescue
          return false
        end
      end

      def self.scanUserRepository(username)
        apps = Hash.new()
        dir = "#{APP_CONFIG['oedl_repository']}/user/#{username}"
        begin
          repo_app_path = Dir.new(dir)
          Dir.chdir(dir)
          entries = Dir.glob("*.rb")
          entries.each do |f|
            c = getDefinition("#{repo_app_path.path}/#{f}")
            apps.merge!(c.properties[:repository][:apps])
          end
        rescue Errno::ENOENT
          Rails.logger.info("No user repository")
        end
        return apps
      end

      def self.scanRepositories(username=nil)
        directories = [APPS_REPOSITORY]
        apps = Hash.new()
        directories.each do |repo|
          next unless File.exists?(repo) and File.directory?(repo)
          repo_app_path = Dir.new(repo)
          Dir.chdir(repo)
          entries = Dir.glob("*.rb")
          entries.delete_if { |x| BLACKLIST.include?(x) } if repo == APPS_REPOSITORY
          Rails.logger.debug entries.inspect
          entries.each do |f|
            c = getDefinition("#{repo_app_path.path}/#{f}")
            apps.merge!(c.properties[:repository][:apps])
          end
        end
        return apps
      end

      def self.uri_for(username)
        return "user:#{username}:"
      end
    end

    # Get the appropiate results for the experiment
    def self.results(experiment,args)
      #ed = experiment.ed
      #ed_content = OMF::Workspace.open_ed(ed.user, "#{ed.id.to_s}.rb")
      #script = OMF::Experiments::ScriptHandler.exec(experiment.id, ed)
      code = IO::read( args[:repository].branch_code_path() )
      script = OMF::Experiments::ScriptHandler.exec_raw(code)
      # Iterate over groups
      app_metrics = Array.new()
      script.properties[:groups].each do |group,v|
        apps = v[:node][:applications]
        metrics = Array.new();
        Rails.logger.info apps.inspect
        apps.each do |app, properties|
          properties[:metrics].each do |name, options|
            metrics.push({:name => name})
          end
          app_metrics.push({:app => app, :metrics => metrics, :raw => false });
        end
      end
      data = OMF::Experiments::GenericResults.new(experiment, args)
      app_metrics = data.get_metrics_by_results() if app_metrics.blank?
      return { :metrics => app_metrics, :results => data }
    end
end

require 'omf/experiments/results'
#require 'omf/experiments/ec'
require 'omf/experiments/proxy'
