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
    return SysImage.find(id)
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
    puts session.inspect
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
  
  def destroy
    @sys_image = resource_find(params[:id])
    @username = User.find(@sys_image.user_id).username
    path = get_sysimage_by_user(@username, @sys_image.name);
    puts path.to_s
    File.delete(path.to_s)
    @sys_image.destroy    
    respond_to do |format|
      format.html { redirect_to(admin_sys_images_url) }
    end
  end
  
  def update
    @sys_image = resource_find(params[:id])
    if (params[:sys_image_id] != -1)
      @sys_image.sys_image_id = params[:sys_image_id]
    end
    respond_to do |format|
      if @sys_image.update_attributes(params[:sys_image])
        format.html { redirect_to(admin_sys_image_path(@sys_image), :notice => 'Sys image was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end
  
  def create
    @sys_image = resource_new(params[:sys_image]) 
    @sys_image.user_id = current_user.id
    if (params[:sys_image_id] != -1)
      @sys_image.sys_image_id = params[:sys_image_id]
    end
    uploaded_io = params[:file]
    path = get_sysimage_by_user(current_user.username, params[:sys_image][:name]);    
    File.open(path, 'w') do |file|
      file.write(uploaded_io.read)
    end
    @sys_image.size = File.size(path.to_s)
    
    respond_to do |format|
      if @sys_image.save
        format.html { redirect_to(admin_sys_image_path(@sys_image), :notice => 'Sys image was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end
end
