class ProjectsController < ApplicationController
  include ProjectsHelper
  before_filter :authenticate
  append_before_filter :is_project_leader, :only => [:assign, :unassign, :make_leader, :update, :destroy]

  layout 'general'
  respond_to :html
  # GET /projects
  # GET /projects.xml
  def index    
    current_page = params[:page]
    if current_page.nil?
      current_page = '1'
    end

    @projects = Project.paginate(:page => current_page)
    #puts @projects[0].attributes.inspect
    @users = User.all
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])
    @experiments = Experiment.where(:project_id => params[:id])
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

  # GET /projects/1/assign
  def assign
    @project = Project.find(params[:id])
    @users = User.all
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])
    uploaded_io = params[:file]
    if @project.save and ProjectsUsers.create({:project_id => @project.id, :user_id => current_user.id, :leader => 't'})
      unless uploaded_io.nil?
        path = project_logo_path_for(@project)
        File.open(path, 'wb') do |file|
          file.write(uploaded_io.read)
        end
      end
     flash["success"] = 'Project was successfully created.'
     return redirect_to(@project)
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
      flash["success"] = 'Project was successfully updated.'
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
      flash["success"] = @user.name.to_s + ' assigned to ' + @project.name.to_s
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
     
     flash["success"] = @user.name.to_s + ' is also leader on ' + @project.name.to_s
     redirect_to(assign_project_path(@project)) 
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
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
      flash["success"] = @user.name.to_s + ' unassigned from ' + @project.name.to_s
      redirect_to(assign_project_path(@project))
    else
      render :action => "assign" 
    end
  end

  private
  def is_project_leader
    project = Project.find(params[:id])
    if (project.users.find(current_user.id).leader == "1" or current_user.admin?)
      return true
    end
    head :forbidden
  end
end
