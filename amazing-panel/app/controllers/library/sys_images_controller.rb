class Library::SysImagesController < Library::ResourceController
  def resource_group()
    return "sysimages"
  end

  def resource()
    return SysImage
  end
  
  def resource_find_all
    return SysImage.all
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
  
  # GET /sys_images
  # GET /sys_images.xml
  #def index
  #  current_page = params[:page]
  #  if current_page.nil?
  #    current_page = "1"
  #  end
  #  @sys_images = filter(params)    
  #  if @sys_images.nil? == false
  #    @sys_images = @sys_images.paginate(:page => current_page)
  #  end
  #  if params[:filter] == "clear"
  #    redirect_to sys_images_path
  #  end
  #  if @error.nil? == false
  #	  @error = "Invalid Filter."
  #  end
  #end

  # GET /sys_images/1
  # GET /sys_images/1.xml
  def show
    @sys_image = resource_find(params[:id])
  end

  # GET /sys_images/new
  # GET /sys_images/new.xml
  def new
    @sys_image = resource_new()
    @baselines = Array.new()
    @baselines.push(["No Baseline", -1])
    SysImage.where("baseline" => true).each do |img| 
      @baselines.push([img.name, img.id])
    end
  end

  # GET /sys_images/1/edit
  def edit
    @sys_image = resource_find(params[:id])
    @baselines = Array.new()
    SysImage.where("baseline" => true).each do |img| 
      @baselines.push([img.name, img.id])
    end
  end

  # POST /sys_images
  # POST /sys_images.xml
  def create
    @sys_image = resource_new(params[:sys_image]) 
    @sys_image.user_id = current_user.id
	@sys_image.sys_image_id = nil
    if (params[:sys_image_id].to_i != -1)
      @sys_image.sys_image_id = params[:sys_image_id]
    end
    uploaded_io = params[:file]
    #path = get_sysimage_by_user(current_user.username, params[:sys_image][:name]);    
    #File.open(path, 'w') do |file|
      #file.write(uploaded_io.read)
    #end
    _size = File.size(uploaded_io)
    if _size > 0
      @sys_image.size = _size
      if @sys_image.save
        write_resource(@sys_image, uploaded_io.read, "ndz")
        OMF::Workspace.create_sysimage(@sys_image, get_path(@sys_image, "ndz")) 
        flash["success"] = 'Sys image was successfully created.'
        redirect_to(@sys_image) 
      else
        render :action => "new" 
      end
    end
  end

  # PUT /sys_images/1
  # PUT /sys_images/1.xml
  def update
    @sys_image = resource_find(params[:id])
    uploaded_io = params[:file]
    if (params[:sys_image_id] != -1)
      @sys_image.sys_image_id = params[:sys_image_id]
    end

    unless uploaded_io.nil?
      _size = File.size(uploaded_io)    
      params[:sys_image].merge!({:size => _size}) 
    end

    if @sys_image.update_attributes(params[:sys_image])
      unless uploaded_io.nil?
        OMF::Workspace.remove_sysimage(@sys_image) 
        write_resource(@sys_image, uploaded_io.read, "ndz")
      end  

      flash["success"] = 'Sys image was successfully updated.'
      redirect_to(@sys_image) 
    else
      render :action => "edit"
    end
  end

  # DELETE /sys_images/1
  # DELETE /sys_images/1.xml
  def destroy
    @sys_image = resource_find(params[:id])
    @username = User.find(@sys_image.user_id).username
    if @ed.destroy
      delete_resource(@sys_image, "ndz")
      OMF::Workspace.remove_sysimage(@sys_image) 
    else
      flash[:error] = "Error deleting System image"      
    end
     redirect_to(sys_images_path) 
  end

  # POST /sys_images/1/image  
  # POST /sys_images/1/image.xml
  def image
    @sys_image = resource_find(params[:id])
    uploaded_io = params[:file]
    _size = File.size(uploaded_io)
    write_resource(@sys_image, uploaded_io.read, "ndz")
    redirect_to(@sys_image) 
  end
end
