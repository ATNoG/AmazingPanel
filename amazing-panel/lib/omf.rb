module OMF 
  class Workspace
    @config = YAML.load_file("#{Rails.root}/config/config.yml")[Rails.env]
    @frisbee = YAML.load_file(@config['aggmgr_frisbee'])
    @frisbee_img_dir = @frisbee['frisbee']['testbed']['default']['imageDir']
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

    def self.create_workspace(user)
      dir_frisbee_path = Pathname.new(@frisbee_img_dir).join('users', user.username)
      
      dir_user_path = Pathname.new(APP_CONFIG['inventory']).join('users', user.username)
      dir_eds_path = dir_user_path.join('eds')
      dir_sysimages_path = dir_user_path.join('sysimages')

      FileUtils.mkdir_p(dir_eds_path)
      FileUtils.mkdir_p(dir_sysimages_path)
      FileUtils.mkdir_p(dir_frisbee_path)     
    end
    
    # create a sys_image 
    def self.create_sysimage(img, target)
      dir_frisbee_path = Pathname.new(@frisbee_img_dir).join('users', img.user.username)
      FileUtils.ln_s(target.realpath, dir_frisbee_path.join(img.id).realpath)      
    end

    def self.remove_sysimage(img)
      dir_frisbee_path = Pathname.new(@frisbee_img_dir).join('users', img.user.username)
      FileUtils.rm dir_frisbee_path.join(img.id).realpath      
    end
  end
end

require 'omf/grid'
require 'omf/experiments'

