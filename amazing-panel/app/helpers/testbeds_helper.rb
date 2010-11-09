module TestbedsHelper
  
  def testbed_properties_for(testbed)
    return YAML.load_file("#{Rails.root}/inventory/testbeds/#{testbed.id}.yml")
  end
  
  def get_nodes_status
    data = File.new('tmp/nodes.json','r').readlines().to_s
    data_json = ActiveSupport::JSON.decode(data)  
    return data_json
  end
  
  def node_actions(id)
    
  end
end
