class Library::SysImagesController < Library::ResourceController
  # GET /sys_images
  # GET /sys_images.xml
  def index
    @sys_images = SysImage.all
  end

  # GET /sys_images/1
  # GET /sys_images/1.xml
  def show
    @sys_image = SysImage.find(params[:id])
  end

  # GET /sys_images/new
  # GET /sys_images/new.xml
  def new
    @sys_image = SysImage.new
  end

  # GET /sys_images/1/edit
  def edit
    @sys_image = SysImage.find(params[:id])
  end

  # POST /sys_images
  # POST /sys_images.xml
  def create
    @sys_image = SysImage.new(params[:sys_image])
    @sys_image.user_id = current_user.id
    uploaded_io = params[:file]
    path = get_sysimage_by_user(current_user.username, params[:sys_image][:name]);    
    File.open(path, 'w') do |file|
      file.write(uploaded_io.read)
    end
    
    respond_to do |format|
      if @sys_image.save
        format.html { redirect_to(@sys_image, :notice => 'Sys image was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /sys_images/1
  # PUT /sys_images/1.xml
  def update
    @sys_image = SysImage.find(params[:id])

    respond_to do |format|
      if @sys_image.update_attributes(params[:sys_image])
        format.html { redirect_to(@sys_image, :notice => 'Sys image was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /sys_images/1
  # DELETE /sys_images/1.xml
  def destroy
    @sys_image = SysImage.find(params[:id])
    @sys_image.destroy
    path = get_sysimage_by_user(current_user.username, @sys_image.name);
    path.delete
    respond_to do |format|
      format.html { redirect_to(sys_images_url) }
    end
  end
end
