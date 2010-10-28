class Admin::UsersController < Users::UsersController
  layout 'admin'
  before_filter :admin_user
     
  def activate
    user = User.find(params[:user_id]);    
    activated = user.activated ? false : true;
    if user.update_attributes({:activated => activated })
      redirect_to admin_user_path(params[:user_id])
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      flash['notice'] = "Successfully deleted User."
      redirect_to admin_users_path
    end
  end
  
  def new
    
  end
  
  def create
  end

end
