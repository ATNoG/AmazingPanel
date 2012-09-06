module OMF
  module GridServices 
    class TestbedService
      attr_accessor :has_map  
      
      private
      def read_properties
        return OMF::GridServices.testbed_properties_load(@id)["testbed"]
      end
      
      def write_properties(hash)
        return OMF::GridServices.testbed_properties_save(@id, hash)
      end

      public
      def initialize(id)
        @id = id
        begin
          @@properties = read_properties
          @@http = Net::HTTP.new(@@properties["server_url"])
          @@path = @@properties["server_path"]
          @has_map = ( @@properties["positions"].nil? ) ? false : true;
        rescue
          @@properties = nil
        end
      end      

      def mapping
        return @@properties["positions"] unless @@properties.nil? or @@properties["positions"].nil?
        nodes = Node.joins(:location => :testbed).where("testbeds.id" => @id).order("id").collect do |n| 
          { "id" => n.id, "hrn" => n.hrn}
        end
        return nodes 
      end

      def disabled
        ds = @@properties["disabled"]
        return ds.keys() unless ds.nil?
      end

      def maintain(node_id, cause="Empty")
        ret = true
        disabled = @@properties["disabled"]
        if disabled.nil? then disabled = Hash.new() end
        if disabled[node_id].nil?
          disabled[node_id] = cause
        else
          disabled.delete(node_id)
          ret = false
        end
        @@properties["disabled"] = disabled
        write_properties({ "testbed" => @@properties })
        @@properties = read_properties()
        return ret
      end
  
      def statusAll
        status = get("power", "status")
        status.delete("type")
        nodes = mapping()
        ds = disabled()
        for n in nodes
          query_id = (n['id'].to_i - 1)
          unless ds.include?(query_id)
            n["status"] = status[query_id.to_s]
          end
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
    
    def self.testbed_properties_save(testbed_id, hash)
      begin
        File.open(properties_file_str(testbed_id), 'w') {|f|
          f.write(hash.to_yaml);
        }
        return true
      rescue 
        return false
      end
    end

    def self.testbed_properties_load(testbed_id)
      return YAML.load_file(properties_file_str(testbed_id))
    end
    
    def self.properties_file_str(id)
      app_config = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
      return "#{app_config['inventory']}/testbeds/#{id}.yml"
    end
    
    def self.testbed_rel_file_str(id, extension="yml")
      app_config = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
      return "#{app_config['inventory']}/testbeds/#{id}.#{extension}"
    end
    
    def self.testbed_status(id)
      ts = TestbedService.new(id)
      return ts.statusAll()
    end
  
    def self.testbed_node_toggle(id, node)
      ts = TestbedService.new(id)
      return ts.toggle(node.to_i - 1)
    end
    
    def self.testbed_node_maintain(id, node)
      ts = TestbedService.new(id)
      return ts.maintain(node.to_i - 1)
    end
  end
end
