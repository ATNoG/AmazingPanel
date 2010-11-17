module TestbedsHelper

    def properties_file_str(id)
     return "#{Rails.root}/inventory/testbeds/#{id}.yml"
    end

    def testbed_properties_for(testbed_id)
      return YAML.load_file(properties_file_str(testbed_id))
    end

end
