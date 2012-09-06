module Admin::SysImagesHelper
  def resource_find_all()
    return SysImage.where(:sys_image_id => nil)
  end
end
