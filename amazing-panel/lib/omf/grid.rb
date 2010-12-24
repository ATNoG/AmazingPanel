module OMF
  module GridServices 

    class TestbedService
      def initialize(id)
        @@id = id
        @@properties = OMF::GridServices.testbed_properties_load(id)["testbed"] 
        @@http = Net::HTTP.new(@@properties["server_url"])
        @@path = @@properties["server_path"]
      end
        
      def mapping
        return @@properties["positions"]
      end
  
      def statusAll
        status = get("power", "status")
        status.delete("type")
        nodes = mapping()
        for n in nodes
          query_id = (n['id'].to_i - 1).to_s
          n["status"] = status[query_id]
        end
        return nodes
      end
          
      def toggle(node_id)
        status = get("power", "toggle", { :node => node_id })
        status = get("power", "status", { :node => node_id })
        status.delete("type")
        return status[node_id.to_s]
      end
  
      def power_on(node_id)
        return get("power", "on", { :node => node_id })
      end
        
      def power_off(node_id)
        return get("power", "off", { :node => node_id })
      end

      protected
      def get(controller, action, args={})
        path = "#{@@path + controller}/#{action}"+(!args[:node].nil? ? "/#{args[:node].to_s}" : "")
        req = Net::HTTP::Get.new(path)
        resp = @@http.request(req)
        ret = ActiveSupport::JSON.decode(resp.body.gsub("'", "\""))
        return ret
        #data = File.new('tmp/nodes.json','r').readlines().to_s
        #status = ActiveSupport::JSON.decode(data)      
        #return status
      end        
    end
    
    def self.testbed_properties_load(testbed_id)
      return YAML.load_file(properties_file_str(testbed_id))
    end
    
    def self.properties_file_str(id)
      return "#{APP_CONFIG['inventory']}/testbeds/#{id}.yml"
    end
    
    def self.testbed_rel_file_str(id, extension="yml")
      return "#{APP_CONFIG['inventory']}/testbeds/#{id}.#{extension}"
    end
    
    def self.testbed_status(id)
      ts = TestbedService.new(id)
      return ts.statusAll()
    end
  
    def self.testbed_node_toggle(id, node)
      ts = TestbedService.new(id)
      system "echo #{node.to_i - 1} > /tmp/logging_dumb"
      return ts.toggle(node.to_i - 1)
      #return true
    end
  end
end
