class ProjectsController < ApplicationController
  include ProjectsHelper
  before_filter :authenticate
  layout 'general'
  # GET /projects
  # GET /projects.xml
  def index    
    @projects = Project.all
    puts @projects[0].attributes.inspect
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    @project = Project.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
  end

  # GET /projects/1/assign
  def assign
    @project = Project.find(params[:id])
    @users = User.all
    respond_to do |format|
      format.html # assign.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])
    uploaded_io = params[:file]
    respond_to do |format|
      if @project.save and ProjectsUsers.create({:project_id => @project.id, :user_id => current_user.id, :leader => 't'})
	path = project_logo_path_for(@project)
	File.open(path, 'wb') do |file|
	  file.write(uploaded_io.read)
	end
        format.html { redirect_to(@project, :notice => 'Project was successfully created.') }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])
    uploaded_io = params[:file]    
    
    respond_to do |format|
      if @project.update_attributes(params[:project])
	if uploaded_io.size > 0
	  path = project_logo_path_for(@project)
	  File.open(path, 'wb') do |file|
	    file.write(uploaded_io.read)
	  end	  
	end
        format.html { redirect_to(@project, :notice => 'Project was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
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
    
    respond_to do |format|
      if @project.update_attributes({:user_ids => tmp})
        format.html { redirect_to(assign_project_path(@project), :success => @user.name.to_s + ' assigned to' + @project.name.to_s) }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "assign" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def make_leader
    id = Integer(params[:user_id])
    @project = Project.find(params[:id])
    @user = User.find(id)
    @project_user = ProjectsUsers.where("project_id = :tid AND user_id = :uid", { :tid => params[:id], :uid => params[:user_id]})
    Project.find(params[:id]).users.delete(@user)
    ProjectsUsers.create({:project_id => params[:id], :user_id => params[:user_id], :leader => 't'})
    
    respond_to do |format|
      format.html { redirect_to(assign_project_path(@project), :success => @user.name.to_s + ' assigned to' + @project.name.to_s) }
      format.xml  { render :xml => @project, :status => :created, :location => @project }      
    end
  end

  # DELETE /projects/1
  # DELETE /projects/1.xml
  def destroy
    @project = Project.find(params[:id])
    @project.destroy

    respond_to do |format|
      format.html { redirect_to(projects_url) }
      format.xml  { head :ok }
    end
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

    respond_to do |format|
      if @project.update_attributes({:user_ids => tmp})
        format.html { redirect_to(assign_project_path(@project), :success => @user.name.to_s + ' unassigned from ' + @project.name.to_s) }
        format.xml  { render :xml => @project, :status => :created, :location => @project }
      else
        format.html { render :action => "assign" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
  end
end