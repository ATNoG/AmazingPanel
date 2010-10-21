class TestbedsController < ApplicationController
  # GET /testbeds
  # GET /testbeds.xml
  def index
    @testbeds = Testbed.all
    @users = User.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @testbeds }
    end
  end

  # GET /testbeds/1
  # GET /testbeds/1.xml
  def show
    @testbed = Testbed.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @testbed }
    end
  end

  # GET /testbeds/new
  # GET /testbeds/new.xml
  def new
    @testbed = Testbed.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @testbed }
    end
  end

  # GET /testbeds/1/edit
  def edit
    @testbed = Testbed.find(params[:id])
  end

  # GET /testbeds/1/assign
  def assign
    @testbed = Testbed.find(params[:id])
    @users = User.all
    respond_to do |format|
      format.html # assign.html.erb
      format.xml  { render :xml => @testbed }
    end
  end

  # POST /testbeds
  # POST /testbeds.xml
  def create
    @testbed = Testbed.new(params[:testbed])
    
    respond_to do |format|
      if @testbed.save and TestbedsUsers.create({:testbed_id => @testbed.id, :user_id => current_user.id, :leader => 't'})
        format.html { redirect_to(@testbed, :notice => 'Testbed was successfully created.') }
        format.xml  { render :xml => @testbed, :status => :created, :location => @testbed }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @testbed.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /testbeds/1
  # PUT /testbeds/1.xml
  def update
    @testbed = Testbed.find(params[:id])

    respond_to do |format|
      if @testbed.update_attributes(params[:testbed])
        format.html { redirect_to(@testbed, :notice => 'Testbed was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @testbed.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /testbeds/1/user/1
  # PUT /testbeds/1/user/1.xml
  def assign_user
    id = params[:user_id]
    @testbed = Testbed.find(params[:id])
    @user = User.find(id)

    tmp = @testbed.user_ids
    if tmp.index(id).nil?
      tmp.push(id)
    end
    
    respond_to do |format|
      if @testbed.update_attributes({:user_ids => tmp})
        format.html { redirect_to(assign_testbed_path(@testbed), :success => @user.name.to_s + ' assigned to' + @testbed.name.to_s) }
        format.xml  { render :xml => @testbed, :status => :created, :location => @testbed }
      else
        format.html { render :action => "assign" }
        format.xml  { render :xml => @testbed.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  def make_leader
    id = Integer(params[:user_id])
    @testbed = Testbed.find(params[:id])
    @user = User.find(id)
    @testbed_user = TestbedsUsers.where("testbed_id = :tid AND user_id = :uid", { :tid => params[:id], :uid => params[:user_id]})
    Testbed.find(params[:id]).users.delete(@user)
    TestbedsUsers.create({:testbed_id => params[:id], :user_id => params[:user_id], :leader => 't'})
    
    respond_to do |format|
      format.html { redirect_to(assign_testbed_path(@testbed), :success => @user.name.to_s + ' assigned to' + @testbed.name.to_s) }
      format.xml  { render :xml => @testbed, :status => :created, :location => @testbed }      
    end
  end

  # DELETE /testbeds/1
  # DELETE /testbeds/1.xml
  def destroy
    @testbed = Testbed.find(params[:id])
    @testbed.destroy

    respond_to do |format|
      format.html { redirect_to(testbeds_url) }
      format.xml  { head :ok }
    end
  end
  
  # DELETE /testbeds/1/user/1
  # DELETE /testbeds/1/user/1.xml
  def unassign_user
    id = Integer(params[:user_id])
    @testbed = Testbed.find(params[:id])
    @user = User.find(id)

    tmp = @testbed.user_ids
    if tmp.index(id).nil? == false
      tmp.delete(id)
    end

    respond_to do |format|
      if @testbed.update_attributes({:user_ids => tmp})
        format.html { redirect_to(assign_testbed_path(@testbed), :success => @user.name.to_s + ' unassigned from ' + @testbed.name.to_s) }
        format.xml  { render :xml => @testbed, :status => :created, :location => @testbed }
      else
        format.html { render :action => "assign" }
        format.xml  { render :xml => @testbed.errors, :status => :unprocessable_entity }
      end
    end
  end
end