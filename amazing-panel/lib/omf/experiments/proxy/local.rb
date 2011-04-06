module OMF::Experiments::Controller
  class LocalProxy < AbstractProxy
    def load_resource_action(img, nodes)
      ns = nodes.collect{ |n| n.hrn }
      comma_nodes = ns.join(",") 
      cmd = "omf load -i users/#{img.user.username}/#{img.id}.ndz -t #{comma_nodes} -e #{@id}"
      info("OMF-ExpCtl: #{cmd}")
      ret = system(cmd)
      debug("OMF-ExpCtl: success? #{ret}")
      return ret
    end

    def load_results_action()        
      url = URI.parse("http://#{APP_CONFIG['aggmgr_url']}")
      http = Net::HTTP.new(url.host, url.port)
      root_path = '/result'
      path = "#{root_path}/dumpDatabase?expID=#{@eid}"
      
      request = Net::HTTP::Get.new(path)
      tmp_basename = "#{APP_CONFIG['omlserver_tmp']}#{@eid.to_s}"      
      
      debug("Requesting AM - GET #{path}")
      response = http.request(request)

      files = [".sq3", "-state.xml", "-prepare.xml", ".log"]      
      files.map!{|f| tmp_basename+f }

      if File.size?(files[0]).nil?
        files.delete_at(0)
        info("No valid results, SQLite3 is empty or doesn't exist")
      end
      
      return files
    end

    def clean_action()
      prepare_log_file = "#{APP_CONFIG['omlserver_tmp']}#{@id}-prepare.xml"
      if File.exists?(prepare_log_file)
        FileUtils.rm(prepare_log_file)
        debug("Clean: \"#{@id}-prepare.xml\" removed")
      end
    end

    def start_action()
      cmd = "omf exec -e #{@eid} #{@experiment.repository.current.branch_code_path}"
      debug("OMF-ExpCtl: #{cmd}")
      return system(cmd)
    end    

    def prepare_state
      status = prepare_status_data
      return status["testbed"]["experiment"]["status"]
    end
    
    def start_state 
      status = start_status_data
      status = status["context"]["experiment"]["status"]
      status.strip! unless status.nil?
      return status
    end
    
    def prepare_status_data
      logpath = "#{APP_CONFIG['omlserver_tmp']}#{@id}-prepare.xml"
      debug("Reading #{logpath}")
      return Hash.from_xml(IO::read(logpath))
    end

    def start_status_data
      logpath = "#{APP_CONFIG['omlserver_tmp']}#{@id}-state.xml"
      debug("Reading #{logpath}")
      return Hash.from_xml(IO::read(logpath))
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
