class Library::EdsController < Library::ResourceController
  before_filter :authenticate
  
  def resource_find_all()
    return Ed.all
  end
  
  def resource_find(id)
    return Ed.find(id)
  end
  
  def resource_new(model=nil)
    if model.nil?
      return Ed.new
    else
      return Ed.new(model)
    end
  end
  
  # GET /eds
  # GET /eds.xml
  def index
    @eds = Ed.all
  end

  # GET /eds/1
  # GET /eds/1.xml
  def show
    @ed = resource_find(params[:id]);    
    path = get_ed_by_user(current_user.username, @ed.name);
    @content = File.open(path, 'r')
  end

  # GET /eds/new
  # GET /eds/new.xml
  def new
    @ed = Ed.new
  end

  # GET /eds/1/edit
  def edit
    @ed = resource_find(params[:id]);
    path = get_ed_by_user(current_user.username, @ed.name);
    @content = File.open(path, 'r')
  end

  # POST /eds
  # POST /eds.xml
  def create
    @ed = resource_new(params[:ed])
    @ed.user_id = current_user.id
    uploaded_io = params[:file]
    path = get_ed_by_user(current_user.username, params[:ed][:name]);
    #path = Rails.root.join(APP_CONFIG['inventory'], current_user.username, 'ed', params[:ed][:name])
    File.open(path, 'w') do |file|
      file.write(uploaded_io.read)
    end
    respond_to do |format|
      if @ed.save
        format.html { redirect_to(eds_path, :notice => 'Ed was successfully created.') }
      else
        format.html { render :action => "new" }
      end
    end
  end

  # PUT /eds/1
  # PUT /eds/1.xml
  def update
    user_id = current_user.id
    @ed = resource_find(params[:id])
    path = get_ed_by_user(current_user.username, params[:ed][:name]);
    File.open(path, 'w') do |file|
      file.write(params[:code])
    end    
    respond_to do |format|
      if @ed.update_attributes(params[:ed])        
        format.html { redirect_to(ed_path(@ed.id), :notice => 'Ed was successfully updated.') }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  # DELETE /eds/1
  # DELETE /eds/1.xml
  def destroy
    @ed = resource_find(params[:id])
    path = get_ed_by_user(current_user.username, @ed.name);
    path.delete
    @ed.destroy
    respond_to do |format|
        format.html { redirect_to(eds_path, :notice => 'Ed was successfully deleted.') }
    end    
  end 
end
