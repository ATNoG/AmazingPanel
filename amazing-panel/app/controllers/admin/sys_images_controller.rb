class Admin::SysImagesController < Library::SysImagesController
  layout 'admin'
  before_filter :admin_user
  
  def resource_find_all
    return SysImage.where(:sys_image_id => nil)
  end
  
  def resource_find(id)
    return SysImage.find(id)
  end
  
  def resource_new(model=nil)
    if model.nil?
      return SysImage.new
    else
      return SysImage.new(model)
    end
  end

end
