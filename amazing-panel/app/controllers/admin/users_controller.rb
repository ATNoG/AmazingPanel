class Admin::UsersController < Users::UsersController
  layout 'admin'
  append_before_filter :admin_user

  def activate
    @user = resource_find(params[:user_id]);
    activated = @user.activated ? false : true;
    if @user.update_attributes({:activated => activated })
      if (activated == true)
        #mail(:from => "admin@amazing.hng.av.it.pt", :to => @user.email) do |format|
        #  format.text
        #end
        create_workspace(@user)
      end
      redirect_to admin_user_path(params[:user_id])
    end
  end
  
  def destroy
    @user = resource_find(params[:id])
    if @user.destroy
      flash['notice'] = "Successfully deleted User."
      redirect_to admin_users_path
    end
  end
  
  def new    
  end
  
  def create
  end
  
  def edit
    @user = resource_find(params[:id])
  end
  
  def update
  end  

  private
  def create_workspace(user)
    OMF::Workspace.create_workspace(user)
  end
end
