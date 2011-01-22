module OMF
  module Experiments
    module Controller
      class Proxy
        attr_accessor :id
        
        def initialize(args)
          if args.class == Fixnum
            args = {:id => args }
          end
          unless args.nil? or args.length == 0
            @id = args[:id]
          end
          @@logger = Logger.new("#{Rails.root.join("log/"+@id.to_s+"-proxylog.log")}")
        end
  
        def check(type)
          exp = Experiment.find(@id)
          case 
          when type == :init
            exps = Experiment.running
            return true if exps.length == 0
          when type == :prepared
            return exp.prepared?
          when type == :started                
            return exp.started?
          end
          return false
        end
  
        def prepare
          unless lock_testbed(testbeds)
            @@logger.debug("Error: Failed To Lock on Prepare Experiment.")
            return false
          end
          trap('INT'){
            status(nil)
            @@logger.debug("KILLED")
            unlock_testbed(testbeds)
            exit
          }
          lock_testbed(testbeds)
          clean_log()
          status(-1)
          e = Experiment.find(@id)
          images = e.resources_map.group(:sys_image_id)
          images.each do |img|
            nodes = e.resources_map.where('sys_image_id' => img.sys_image).map! { |x| x.node.hrn }
            load_resource_map(img, nodes)
          end          
          Experiment.verify_active_connections!
          status(0)        
          unlock_testbed(testbeds)
          return true
        end
  
        def start
          @@logger.debug("Start Experiment: Invoked")
      experiment = Experiment.find(@id)
          runs = experiment.runs
          exp_id = "#{@id.to_s}_#{runs}"
          @@logger.debug("Start Experiment: Locking experiment")
          unless lock_testbed(testbeds)
            @@logger.debug("Error: Failed to Lock on Start Experiment")
            return false 
          end
          trap('INT'){
            status(2)
            @@logger.debug("KILLED")
            unlock_testbed(testbeds)
            exit
          }
          status(1)
  
          @@logger.debug("STARTING! #{Process.pid}")
          ret = system("omf exec -e #{exp_id} #{OMF::Workspace.ed_for(experiment.ed.user, experiment.ed.id.to_s)}");
      @@logger.debug("start: #{ret.to_s}")
          #sleep 5 # 'XXX' - REMOVE DUMMY
      @@logger.debug("get_results: #{exp_id.to_s}")
          get_results(exp_id, experiment, runs)
          @@logger.debug("FINISHING!")
          status(3)
          inc_runs()
          unlock_testbed(testbeds)
        end
  
        def stop
          @@logger.debug("STOP puts pid => #{Process.pid}")
          data = current_lock(testbeds)
          @@logger.debug("Current Lock: #{data.inspect}")
          begin
            pp data
            Process.kill('INT', data["pid"] )
            return true
          rescue 
            @@logger.debug("NO PID")
            return false
          end
        end
  
        def prepare_status
          if !File.exists?(APP_CONFIG['omf_load_log'])
        @@logger.debug("No progress file.")
          return { :nodes => Hash.new(), :status => "" }
      end
          
        nodes = Hash.new()
      state = ""
  
        stat = IO::read(APP_CONFIG['omf_load_log'])
        status = Hash.from_xml(stat)
      sum_prog = Hash.new()
          slice = status["testbed"]["id"]
      progress = status["testbed"]["progress"]
      unless progress.nil?
        progress.each do |k,v|
        #system "echo #{k} > /tmp/foobar.log"
        node = Node.find_by_hrn(k)
        next if  node.nil?
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
          state = ""
        sum_prog.each do |k, p| 
            if p == 100 
              state = "PREPARED";
            else
              state = "";
              break;
            end
          end
      return { :slice => slice, :nodes => nodes, :state => state }
      end
        
      def experiment_status
      #file = "#{APP_CONFIG['omlserver_tmp']}#{@id}-state.xml"
          #if !File.exists?(file)
      #  return { :status => "" }
      #end         
        #stat = IO::read(file)
        #stat = Hash.from_xml(stat)
      #system "echo #{k} > /tmp/foobar.log"
          exp = Experiment.find(@id)
          msg = ""
          if exp.started? 
            msg = "Running..."
          elsif exp.finished? 
            msg = "Experiment Finished:"
          end
          return msg
      end
  
        def runs        
          entries = Pathname.new("#{APP_CONFIG['exp_results']}/#{@id}").children.select{|e| e.directory?}.map{|d| d.basename.to_s}
          #@@logger.debug(entries.inspect)
          return entries
        end
  
      def log(slice="", from_line=-1)
          e = Experiment.find(@id)
          runs = e.runs
          preparing_file = "#{APP_CONFIG['omlserver_tmp']}#{slice}.log"
          running_file = "#{APP_CONFIG['omlserver_tmp']}#{@id}_#{runs}.log"
          finished_file = "#{APP_CONFIG['inventory']}/experiments/#{@id}_#{runs}.log"
          
          lines = IO::readlines(running_file) if e.started? and File.exists?(running_file)
          lines = IO::readlines(preparing_file) if e.preparing? and File.exists?(preparing_file)
          lines = IO::readlines(finished_file) if e.finished? and File.exists?(finished_file)
          
           
          lines_content = ""
          unless lines.nil?
            lines.reverse_each { |line|
              lines_content += line
            }
          end 
          return lines_content
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
      cmd = "omf load -i users/#{img.sys_image.user.username}/#{img.sys_image_id}.ndz -t #{comma_nodes}"
           ret = system(cmd)
          @@logger.debug("#{cmd} => #{ret}")
        end
  
        def inc_runs
          experiment = Experiment.find(@id)
          experiment.update_attributes(:runs => experiment.runs.to_i + 1)
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
            @@logger.info("#{lock} => #{ret.to_s}")
            if ret == true
              return false
            end
          end
          return data;
        end
  
        def unlock_testbed(t_ids)
          t_ids.each do |t_id|
            lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
            @@logger.debug("LOCK: #{lock}")
            if (File.exists?(lock))            
              f = ActiveSupport::JSON.decode(IO::read(lock))
              if (f["pid"].to_i == Process.pid)
                File.unlink(lock)
                @@logger.debug("UNLOCKED")
                return true
              end
            end
          end
          return false
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
  
        def get_results(exp_id, experiment, run)
          http = Net::HTTP.new(APP_CONFIG['aggmgr_url'])
          root_path = '/result/'
          path = "#{root_path}/dumpDatabase?expID=#{@id}"
          request = Net::HTTP::Get.new(path)
          exp_path = "#{APP_CONFIG['exp_results']}/#{experiment.id}/#{run}"
          tmp_basename = "#{APP_CONFIG['omlserver_tmp']+exp_id.to_s}"
          exp_basename = "#{exp_path}/#{exp_id.to_s}"
          #response = http.request(request)
          FileUtils.mkdir_p(exp_path)
          File.copy("#{tmp_basename}.sq3", "#{exp_basename}.sq3")
          @@logger.debug("File.copy(#{tmp_basename}.sq3, #{exp_basename}.sq3)")
  
          File.copy("#{tmp_basename}-state.xml", "#{exp_basename}-state.xml")
          @@logger.debug("File.copy(#{tmp_basename}-state.xml, #{exp_basename}-state.xml)")
  
          File.copy("#{APP_CONFIG['omlserver_tmp']}omf-log.xml", "#{exp_basename}-prepare.xml")
          @@logger.debug("File.copy(#{tmp_basename}omf-log.xml, #{exp_basename}-prepare.xml)")
  
          File.copy("#{tmp_basename}.log", "#{exp_basename}.log")
          @@logger.debug("File.copy(#{tmp_basename}.log, #{exp_basename}.log)")
          #File.copy("#{APP_CONFIG['omlserver_tmp']}#{@id}.sq3", "#{APP_CONFIG['exp_results']}#{@id}.sq3")
          #File.copy("#{APP_CONFIG['omlserver_tmp']}#{@id}-state.xml", "#{APP_CONFIG['exp_results']}#{@id}-state.xml")
          #File.copy("#{APP_CONFIG['omlserver_tmp']}omf-log.xml", "#{APP_CONFIG['exp_results']}#{@id}-prepare.xml")
          #File.copy("#{APP_CONFIG['omlserver_tmp']}#{@id}.log", "#{APP_CONFIG['exp_results']}#{@id}.log")
          #@@logger.debug("cp #{APP_CONFIG['omlserver_tmp']+@id.to_s}.sq3 #{APP_CONFIG['exp_results']+@id.to_s}.sq3")
          #if response.status == 200
          #  FileUtils.cp("#{APP_CONFIG['omlserver_tmp']+@id}.sq3", "#{APP_CONFIG['exp_results']+@id}.sq3")
          #end
        end

      end
    end
  end
end
