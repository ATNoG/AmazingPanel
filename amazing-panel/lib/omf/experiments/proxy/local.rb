module OMF::Experiments::Controller
  class LocalProxy < AbstractProxy
    def load_resource_action(img, nodes)
      ns = nodes.collect{ |n| n.hrn }
      comma_nodes = ns.join(",") 
      cmd = "omf load -i users/#{img.sys_image.user.username}/#{img.sys_image_id}.ndz -t #{comma_nodes} -e #{@id}"
      info("OMF-ExpCtl: #{cmd}")
      ret = system(cmd)
    end

    def load_results_action()            
      http = Net::HTTP.new(APP_CONFIG['aggmgr_url'])
      root_path = '/result/'
      path = "#{root_path}/dumpDatabase?expID=#{exp_id}"
      
      request = Net::HTTP::Get.new(path)
      tmp_basename = "#{APP_CONFIG['omlserver_tmp']}#{@eid.to_s}"      
      
      debug("Requesting AM - GET #{path}")
      response = http.request(request)

      files = [".sq3", "-state.xml", "-prepare.xml", ".log"]      
      files.map!{|f| tmp_basename+f }
      @experiment.repository.current.save_run(@run, files)
      info("Run ##{@run} files copied")
      return files
    end

    def clean_action()
      prepare_log_file = "#{APP_CONFIG['omlserver_tmp']}/#{@id}-prepare.xml"
      if File.exists?(prepare_log_file)
        FileUtils.rm(prepare_log_file)
        debug("Clean: \"#{@id}-prepare.xml\" removed")
      end
    end

    def prepare_state
      status = prepare_status_data
      return status["testbed"]["experiment"]["status"]
    end
    
    def start_state 
      status = prepare_status_data
      status = status["context"]["experiment"]["status"]
      status.strip! unless status.nil?
      return status
    end

    def prepare_status_data
      return Hash.from_xml(IO::read("#{APP_CONFIG['omlserver_tmp']}/#{id}-state.xml"))
    end

    def check_nodes_status(status_data)    
      nodes = Hash.new()
      nodesProgress = status_data["testbed"]["experiment"]["progress"]
      unless nodesProgress.nil?
        nodesProgress.each do |k,v|
          #system "echo #{k} > /tmp/foobar.log"
          node = Node.find_by_hrn(k)
          next if node.nil?
          id = node.id
          case v["status"]
          when "LOADING"
            msg = "Loading image..."
          when "RESETTING"
            msg = "Resetting node..."
          when "DONE.ERR"
            msg = "Node failed to load"
          when "DONE.TIMEDOUT"
            msg = "Node timed-out"
          when "DONE.OK"
            msg = "Image loaded"
          else
            msg = "Ops, unknown state!"
          end
          nodes[id.to_s] ={ :progress => v["percentage"], :state => v["status"], :msg => msg }
        end
      end
      return nodes
    end

    def check_overall_status(status_data)      
      state = status_data["testbed"]["experiment"]["status"]
      cond_set_status(state, true)
    end
  end
end
