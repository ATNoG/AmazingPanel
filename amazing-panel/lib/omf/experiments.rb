require 'ruby_parser'
require 'pp'

module OMF
  module Experiments
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

    class GenericResults
      class OMLGenerated < ActiveRecord::Base
        abstract_class = true
      end
      class DataGenerated < ActiveRecord::Base
        abstract_class = true
      end
      class Sender < OMLGenerated
        set_table_name('_senders')
      end
      class ExperimentMetadata < OMLGenerated
        set_table_name('_experiment_metadata')
      end
      class Data < DataGenerated
        abstract_class = true
      end
      
      attr_accessor :tables, :config
      def initialize(experiment, app={})
        @config = { 
          :adapter => "sqlite3", 
          :database => "#{APP_CONFIG['exp_results']}#{experiment.id}.sq3" }
        @tables = { }
        if (app == {})
          load_models(self.class)
        else
          create_models(app)
        end
      end
      
      def select_model_by_metric(app, metrics)
        ts = Array.new()
        Data.connection.tables.each do |t|
          if (app.select {|e| t.include?(e) }).length > 0         
          #pp "for <#{t}> --> #{has_app}"
            if (metrics.select {|mt| t.include?(mt[:name]) }).length > 0
              ts.push(t)
            end
          end
        end
        if ts.length == 1
          Data.set_table_name(ts[0])
          return Data
        end
        return nil
      end

      def select_model(table)
        Data.set_table_name(table)
        return Data;
      end
      
      protected
      def load_models(klass)
        klass.constants.each do |rt|
          rt_class = klass.const_get(rt)
          rt_superclass = rt_class.superclass
          unless rt_superclass != DataGenerated
            #puts "Class: #{rt_class}"
            rt_class.establish_connection(@config)
            @tables[rt_class.to_s] = rt_class
          end
        end
      end   
    end
    
    class ExperimentControllerProxy
      attr_accessor :id
      
      def initialize(args)
        if args.class == Fixnum
          args = {:id => args }
        end
        unless args.nil? or args.length == 0
          @id = args[:id]
        end
      end

      def check(type)
        ActiveRecord::Base.verify_active_connections!        
        case 
        when type == :init
          exps = Experiment.where("status=0 or status=-1 or status=1 ")
          return true if exps.length == 0
        when type == :prepared
          return true if Experiment.find(@id).status == 0
        when type == :started                
          return true if Experiment.find(@id).status == 1
        end
        return false
      end

      def prepare
        lock_testbed(testbeds)
				clean_log()
        status(-1)
        ActiveRecord::Base.verify_active_connections!
        e = Experiment.find(@id)
        images = e.resources_map.group(:sys_image_id)
        images.each do |img|
          nodes = e.resources_map.where('sys_image_id' => img.sys_image).map! { |x| x.node.hrn  }
          load_resource_map(img, nodes)
        end          
        Experiment.verify_active_connections!
        status(0)        
        unlock_testbed(testbeds)
        return true
      end

      def start
        ActiveRecord::Base.verify_active_connections!
		experiment = Experiment.find(@id)
        ret = lock_testbed(testbeds)
        trap('INT'){
          status(2)
          puts "KILLED"
          unlock_testbed(testbeds)
          exit
        }
        status(1)

        puts "STARTING! #{Process.pid}"
        ret = system("omf exec -e #{@id} #{OMF::Workspace.ed_for(experiment.ed.user, experiment.ed.id.to_s)} ");
				puts "start: #{ret.to_s}"
        #sleep 5 # 'XXX' - REMOVE DUMMY
        get_results
        File.copy("#{APP_CONFIG['omlserver_tmp']}#{@id}.sq3", "#{APP_CONFIG['exp_results']}#{@id}.sq3")
        File.copy("#{APP_CONFIG['omlserver_tmp']}#{@id}-state.xml", "#{APP_CONFIG['exp_results']}#{@id}-state.xml")
        File.copy("#{APP_CONFIG['omlserver_tmp']}omf-log.xml", "#{APP_CONFIG['exp_results']}#{@id}-prepare.xml")
        puts "FINISHING!"
        status(2)
        unlock_testbed(testbeds)
      end

      def stop
        puts "STOP puts pid => #{Process.pid}"
        data = current_lock(testbeds)
        begin
          pp data
          Process.kill('INT', data["pid"] )
          unlock_testbed(testbeds)
          return true
        rescue 
          puts "NO PID"
          return false
        end
      end

      def prepare_status
      	if !File.exists?(APP_CONFIG['omf_load_log'])
					system "echo nofile > /tmp/foobar.log"
					return { :nodes => Hash.new(), :status => "" }
				end
				
				system "echo dumbass > /tmp/foobar.log"
    		nodes = Hash.new()
				state = ""

	      stat = IO::read(APP_CONFIG['omf_load_log'])
	      status = Hash.from_xml(stat)
			  sum_prog = Hash.new()
				progress = status["testbed"]["progress"]
				unless progress.nil?
			    progress.each do |k,v|
						#system "echo #{k} > /tmp/foobar.log"
					  node = Node.find_by_hrn(k)
						next if	node.nil?
						id = node.id
						if v["status"] == "SUCCESS" then v["percentage"] = 100; end;
					  sum_prog[id] = v["percentage"].to_i
					  s = v["status"]
					  msg = ""
					  case 
							when s == "UP"
					      msg = "Loading image..."
					    when s == "DOWN"
					      msg = "Waiting for node..."
			        when s == "FAILED"
					  	  msg = "Node failed to load..."
						end
		  			nodes[id.to_s] ={ :progress => v["percentage"], :state => v["status"], :msg => msg } 
				  end
    		end
      	state = "PREPARED"
			  sum_prog.each do |k, p| if p != 100 then state = "";break;end;end;
				return { :nodes => nodes, :state => state }
			end
			
			def experiment_status
				file = "#{APP_CONFIG['omlserver_tmp']}#{@id}-state.xml"
      	if !File.exists?(file)
					return { :status => "" }
				end		     
				 stat = IO::read(file)
	      stat = Hash.from_xml(stat)
				#system "echo #{k} > /tmp/foobar.log"
				return ""
			end

			def logs(params={})
			end

			protected
			def clean_log
				if File.exists?(APP_CONFIG['omf_load_log'])
      		FileUtils.rm "#{APP_CONFIG['omf_load_log']}"
				end
			end

      def status(v)
        ActiveRecord::Base.verify_active_connections!        
        Experiment.find(@id).update_attributes(:status => v)
      end
      
      def testbeds
        ActiveRecord::Base.verify_active_connections!
        return Experiment.find(@id).resources_map.group(:testbed_id).map{ |t| t.testbed_id }
      end

      def load_resource_map(img, nodes)        
        comma_nodes = nodes.join(",");
				cmd = "omf load -i users/#{img.sys_image.user.username}/#{img.sys_image_id}.ndz -t #{comma_nodes} > /tmp/omf_load_cmg.log"
				system("echo #{cmd} > /omf_load_log")
				#system("echo `#{cmd}` > /omf_load_log_2")
       	ret = system(cmd)
        puts "omf -i #{img.sys_image_id}.ndz -t #{comma_nodes} => #{ret}"
      end

      def current_lock(t_ids)
        data = {} 
        t_ids.each do |t_id|
          lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
          f = ActiveSupport::JSON.decode(IO::read(lock))
          if f["experiment"] == @id
            data.merge!(f)
          end
        end
        return data
      end

      def lock_testbed(t_ids)
        ret = true
        data = { :experiment => @id, :pid => Process.pid }
        t_ids.each do |t_id|
          lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
          unless (ret = File.exists?(lock))
            open(lock, "w") { |f|
              f.write(ActiveSupport::JSON.encode(data))          
            }
          end
          if ret == true
            return false
          end
        end
        return data;
      end

      def unlock_testbed(t_ids)
        ret = true
        t_ids.each do |t_id|
          lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
          if (ret = File.exists?(lock))            
            f = ActiveSupport::JSON.decode(IO::read(lock))
            if (f["pid"].to_i == Process.pid)
              File.unlink(lock)
              puts "UNLOCKED"
            end
          else
            return 
          end
        end
        return ret
      end


      def op_testbed(t_ids, global=false, &block)
        ret = false
        child = fork {
          if lock_testbed(t_ids)
            yield
            if global==false
              unlock_testbed(t_ids)
            end
          end
        }        
        if child
          ret = Process.detach(child)          
        end
        return ret
      end

      def get_results
        http = Net::HTTP.new(APP_CONFIG['aggmgr_url'])
        root_path = '/result/'
        path = "#{root_path}/dumpDatabase?expID=#{@id}"
        request = Net::HTTP::Get.new(path)
        #response = http.request(request)
        FileUtils.cp("#{APP_CONFIG['omlserver_tmp']+@id.to_s}.sq3", "#{APP_CONFIG['exp_results']+@id.to_s}.sq3")
        puts "cp #{APP_CONFIG['omlserver_tmp']+@id.to_s}.sq3 #{APP_CONFIG['exp_results']+@id.to_s}.sq3"
        #if response.status == 200
        #  FileUtils.cp("#{APP_CONFIG['omlserver_tmp']+@id}.sq3", "#{APP_CONFIG['exp_results']+@id}.sq3")
        #end
      end
    end
    
    # Get the appropiate results for the experiment
    def self.results(experiment)
      ed = experiment.ed
      ed_content = OMF::Workspace.open_ed(ed.user, "#{ed.id}.rb")
      parser = OMF::Experiments::OEDLParser.new(ed_content)
      data = OMF::Experiments::GenericResults.new(experiment)
      return { :metrics => parser.getApplicationMetrics(), :results => data }
    end
  end
end
