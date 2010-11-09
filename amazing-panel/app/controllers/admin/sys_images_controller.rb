class Admin::SysImagesController < Library::SysImagesController
  layout 'admin'
  before_filter :admin_user
  
  def resource()
    return SysImage
  end
  
  def resource_find_all
    return SysImage.where(:sys_image_id => nil)
  end
  
  def resource_find(id)
    return SysImage.find(id).where(:sys_image_id => nil)
  end
  
  def resource_new(model=nil)
    if model.nil?
      return SysImage.new
    else
      return SysImage.new(model)
    end
  end
  
  # GET /admin/sys_images
  # GET /admin/sys_images.xml
  def index
    current_page = params[:page]
    if current_page.nil?
      current_page = "1"
    end
    @sys_images = filter(params)    
    if @sys_images.nil? == false
      tmp = Array.new
      @sys_images.each do |s|
	if s.sys_image_id.nil?
	  tmp.push(s)
	end
      end
      puts "result:"+tmp.inspect
      @sys_images = tmp.paginate(:page => current_page)      
    end

    if @error.nil? == false
	@error = "Invalid Filter."
    end
  end
end
