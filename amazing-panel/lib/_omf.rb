module OMF 
  class Workspace
    @config = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]

    def self.resource_for(user, resource, filename)
      return Pathname.new(@config['inventory']).join('users', user.username, resource, filename)
    end

    def self.ed_for(user, file)
      return resource_for(user, "eds", file)
    end
  
    def self.sys_image_for(user, file)
      return resource_for(user, "sysimages", file)
    end

    def self.open_ed(user, file)
      f = IO::read(ed_for(user,file).to_s)
      return f;
    end
  end
end

require 'omf/grid'
require 'omf/_experiments'

