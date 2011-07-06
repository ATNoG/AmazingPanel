load 'omf.rb'
load 'omf/experiments.rb'

class ProjectsController < ApplicationController
  include OMF::Experiments::Controller
  include ProjectsHelper

  load_and_authorize_resource :project
  prepend_before_filter :authenticate

  #append_before_filter :is_public, :only => [:show, :users]   
  #append_before_filter :is_project_leader, :only => [:edit, :assign, :assign_user, :make_leader, :update, :destroy]
  append_before_filter :is_only_leader, :only => [:unassign_user]

  layout 'workspaces'
  respond_to :html, :json

  # GET /projects
  # GET /projects.xml
  def index    
    current_page = params[:page]
    if current_page.nil?
      current_page = '1'
    end

    _ps = []
    _pub_ps = []
    _priv_ps = []
    Project.all.select do |p| 
      if !project_is_user_assigned?(p, current_user.id)
        _ps.push(p)
      elsif !p.private?
        _pub_ps.push(p)
      else
        _priv_ps.push(p)
      end
    end
    @projects = _ps.paginate(:page => current_page)
    @public_projects = _pub_ps.paginate(:page => current_page)
    @private_projects = _priv_ps.paginate(:page => current_page)
    #@public_projects = Project.all.select { |p| !project_is_user_assigned?(p, current_user.id) ? true : false }.collect { |p| [p.name, p.id] }
    #puts @projects[0].attributes.inspect
    @users = User.all
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    @experiments = Experiment.where(:project_id => params[:id])
    _res = Hash.new() 
    @experiments.each do |e|
        _res[e.id] = false
        runs = e.runs
        if runs > 0
          _res[e.id] = true
        end
    end
    @results = _res
    session[:project_id] = params[:id]
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    @project = Project.new
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  def users
    current_page = params[:page]
    if current_page.nil?
      current_page = 1
    end
    @project = Project.find(params[:id])
    term = params[:term]    
    name = params[:name]
    email = params[:email]
    fields = "id,name,email"
    #if params.has_key?('name')
    if (params.has_key?(:type) and params[:type] == "unassigned")
      select = User.select(fields)
      query = (term.nil? or term.length==0) ? select.all : select.where(["name LIKE :name", {:name => "%#{term}%"}])
      @users = query.delete_if { |u| project_is_user_assigned?(@project, u.id) == false }
    else
      select = Project.find(params[:id]).users.select(fields+",leader").limit(50)
      query = (term.nil? or term.length==0)  ? select.all : select.where(["name LIKE :name", {:name => "%#{term}%"}])
      @users = query
    end
      @users = @users.length == 0 ? [{}] : @users;
      @users = @users.paginate(:page => current_page)
      respond_with(@users)
  end

  # GET /projects/1/assign
  def assign
    current_page = params[:page]
    if current_page.nil?
      current_page = 1
    end
    @project = Project.find(params[:id])
    @users = User.all.delete_if { |u| project_is_user_assigned?(@project, u.id) == false }
    @users = @users.paginate(:page => current_page)
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])
    uploaded_io = params[:file]
    begin
      if @project.save and ProjectsUsers.create({:project_id => @project.id, :user_id => current_user.id, :leader => 't'})
        unless uploaded_io.nil?
          path = project_logo_path_for(@project)
          File.open(path, 'wb') do |file|
            file.write(uploaded_io.read)
          end
        end
       flash["success"] = t("amazing.project.created")
       return redirect_to(@project)
      end
    rescue ActiveRecord::StatementInvalid
      @project.errors[:name] = :unique
    end
    render :action => "new"
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])
    uploaded_io = params[:file]
    if @project.update_attributes(params[:project])
      unless uploaded_io.nil? or uploaded_io.size == 0
        path = project_logo_path_for(@project)
    	File.open(path, 'wb') do |file|
    	  file.write(uploaded_io.read)
    	end	  
      end
      #flash["success"] = 'Project was successfully updated.'
      flash["success"] = t("amazing.project.updated")
      return redirect_to(@project)
    end
    render :action => "edit" 
  end

  # PUT /projects/1/user/1
  # PUT /projects/1/user/1.xml
  def assign_user
    id = params[:user_id]
    @project = Project.find(params[:id])
    @user = User.find(id)

    tmp = @project.user_ids
    if tmp.index(id).nil?
      tmp.push(id)
    end
      
    if @project.update_attributes({:user_ids => tmp})
      #flash["success"] = @user.name.to_s + ' assigned to ' + @project.name.to_s
      flash["success"] = t("amazing.project.assigned", :name => @user.name.to_s, :project => @project.name.to_s)
      return redirect_to(assign_project_path(@project))
    end
    render :action => "assign"
  end
  
  def make_leader
     id = Integer(params[:user_id])
     @project = Project.find(params[:id])
     @user = User.find(id)
     @project_user = ProjectsUsers.where("project_id = :tid AND user_id = :uid", 
                                  { :tid => params[:id], :uid => params[:user_id]})
     Project.find(params[:id]).users.delete(@user)
     ProjectsUsers.create({:project_id => params[:id], :user_id => params[:user_id], :leader => 't'})
     
     #flash["success"] = @user.name.to_s + ' is manager on ' + @project.name.to_s
     flash["success"] = t("amazing.project.manager", :name => @user.name.to_s, :project => @project.name.to_s)
     redirect_to(assign_project_path(@project)) 
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @experiments = Experiment.where("project_id = :project_id", {:project_id => @project.id})
    @experiments.delete_all
    @project.destroy

    redirect_to(projects_url) 
  end
  
  # DELETE /projects/1/user/1
  # DELETE /projects/1/user/1.xml
  def unassign_user
    id = Integer(params[:user_id])
    @project = Project.find(params[:id])
    @user = User.find(id)

    tmp = @project.user_ids
    if tmp.index(id).nil? == false
      tmp.delete(id)
    end
    if @project.update_attributes({:user_ids => tmp})
      flash["success"] = t("amazing.project.unassigned", :name => @user.name.to_s, :project => @project.name.to_s)
      #flash["success"] = @user.name.to_s + ' unassigned from ' + @project.name.to_s
      redirect_to(assign_project_path(@project))
    else
      render :action => "assign" 
    end
  end

  private
  def is_public
    begin
      project = Project.find(params[:id])
      is_assigned = project.users.where(:id => current_user.id).exists?
      if !is_assigned and project.private?        
        render 'shared/403', :status => 403
        return false
      end

    rescue ActiveRecord::RecordNotFound
      render 'shared/404', :status => 404
      return false
    end
    return true
  end

  def is_project_leader
    project = Project.find(params[:id])
    begin
    if (project.users.find(current_user.id).leader == "1" or current_user.admin?)
      return true
    end
    rescue ActiveRecord::RecordNotFound
      render 'shared/403', :status => 403
      return false
    end
  end
  
  def is_only_leader  
    if !is_project_leader
      return false
    end
    if params[:user_id].to_i != current_user.id
      return true
    end
    leaders = ProjectsUsers.where({:project_id => params[:id], :leader => '1'})
    if leaders.length == 1
      flash["info"] = t("errors.project.only_one_manager")
      redirect_to(assign_project_path(@project))
      return false
    end
    return true
  end
end
