require 'omf.rb'

class Library::EdsController < Library::ResourceController
  include OMF::GridServices
  include OMF::Experiments
  include OMF::Experiments::OEDL
  include Library::EdsHelper

  respond_to :json, :html, :only => [:doc, :code]

  def resource_group()
    return "eds"
  end

  def resource()
    return Ed
  end

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
  #def index
  #  current_page = params[:page]
  #  if current_page.nil?
  #    current_page = "1"
  #  end
  #  @eds = filter(params)
  #  if @eds.nil? == false
  #    @eds = @eds.paginate(:page => current_page)
  #  end

  #  if @error.nil? == false
  #	  @error = "Invalid Filter."
  #  end
  #end

  # GET /eds/1
  # GET /eds/1.xml
  def show
    @ed = resource_find(params[:id]);
    path = get_path(@ed, "rb");
    @content = File.open(path, 'r')
  end

  # GET /eds/new
  # GET /eds/new.xml
  def new
    @ed = Ed.new
    @testbed = Testbed.first
    service = OMF::GridServices::TestbedService.new(@testbed.id)
    @has_map = service.has_map
    unless ["js", "html"].include?(params[:format])
      @nodes = service.mapping();
    end
  end

  # GET /eds/1/edit
  def edit
    @ed = resource_find(params[:id]);
    path = get_path(@ed, "rb");
    @content = File.open(path, 'r')
  end

  # POST /eds
  # POST /eds.xml
  def create
    @ed = resource_new(params[:ed])
    @ed.user_id = current_user.id
    uploaded_io = params[:file]
    code = params[:ed_code]
    content = code unless code.nil?
    content = uploaded_io.read unless uploaded_io.nil?

    if !content.nil? and @ed.save
      #path = get_path(@ed, "rb");
      #File.open(path, 'w') do |file|
        #file.write(uploaded_io.read)
      #end
      write_resource(@ed, content, "rb")
      params[:apps].each do |uri, code|
        ScriptHandler.writeDefinition(uri, code)
      end
      flash[:success] = t("amazing.ed.created")
      redirect_to(eds_path)
    else
      @ed.errors[:file] = " or code needed."

      #redirect_to(new_ed_path)
      render :action => "new"
      #format.html { render :action => "new" }
    end
  end

  # PUT /eds/1
  # PUT /eds/1.xml
  def update
    user_id = current_user.id
    @ed = resource_find(params[:id])
    @username = User.find(@ed.user_id)
    path = get_path(@ed, "rb");
    content = params[:file].nil? ? params[:code] : params[:file].read
    #if params[:file].nil?
    #  File.open(path, 'w') do |file|
	#    file.write(params[:code])
    #  end
    #else
    #  uploaded_io = params[:file]
    #  path = get_path(@ed, "rb");
    #  File.open(path, 'w') do |file|
    # 	file.write(uploaded_io.read)
    #  end
    #end
    write_resource(@ed, content, "rb")
    if @ed.update_attributes(params[:ed])
      flash[:success] = t("amazing.ed.updated")
      redirect_to(ed_path)
    else
      render :action => "edit"
    end
  end

  # DELETE /eds/1
  # DELETE /eds/1.xml
  def destroy
    @ed = resource_find(params[:id])
    @username = User.find(@ed.user_id)
    #path = get_ed_by_user(@username.username, @ed.id);
    #path = get_path(@ed, "rb");
    #File.delete(path.to_s)
    #@ed.destroy
    #respond_to do |format|
    #    format.html { redirect_to(eds_path, :notice => 'Ed was successfully deleted.') }
    #end

    if @ed.destroy
      delete_resource(@ed, extension="rb");
      flash[:success] = t("amazing.ed.destroy");
      return redirect_to(eds_path);
    end
    redirect_to(eds_path, :error => t("errors.ed.destroy"));
  end

  # POST /eds/code.js
  def code
    params[:timeline] = timeline(params[:timeline])
    groups = params[:meta][:groups]
    groups.each do |index, group|
      if group.has_key?(:nodes)
        nodes_hrn = Array.new()
        group[:nodes].each do |n|
          nodes_hrn.push(Node.find(n).hrn)
        end
        groups[index][:nodes] = nodes_hrn
      end
    end

    repo = ScriptHandler.scanRepositories(current_user.username)
    @apps = Hash.new();
    params[:apps][:applications].each do |uri, app|
      args = [uri, app[:name], app]
      @apps[uri] = Generator.new().from_sexp(:createApplicationDefinition, args)
      definition = ScriptHandler.getDefinition(nil, @apps[uri])
      repo[uri] = definition.properties[:repository][:apps][uri]
    end
    scriptgen = Generator.new({:meta => params, :repository => repo})
    @code = scriptgen.to_s();
  end

  def doc
    type = params[:type]
    app = params[:name]
    scan if type == "all"
    definition(app) if !app.nil?
    respond_with(@apps.to_json)
  end

  private
  def scan
    @apps = ScriptHandler.scanRepositories(current_user.username)
    add_namespace()
  end

  def definition(app)
    @apps = ScriptHandler.getDefinition(app)
    unless @apps.nil?
      @apps = @apps.properties[:repository][:apps]
    end
    add_namespace()
  end
  def user_oedl_repository
    ScriptHandler.uri_for(current_user.username)
  end

  def add_namespace
    @apps[:__namespace__] = user_oedl_repository
  end
end
