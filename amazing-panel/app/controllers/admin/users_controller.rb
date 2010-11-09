class Admin::UsersController < Users::UsersController
  layout 'admin'
  before_filter :admin_user

  def index
    current_page = params[:page]
    if current_page.nil?
      current_page = "1"
    end
    @users = filter(params)
    puts "session: "+@users.inspect
    if @users.nil? == false
      @users = @users.paginate(:page => current_page)
    end

    if @error.nil? == false
	@error = "Invalid Filter."
    end
  end
  
  def activate
    user = resource_find(params[:user_id]);    
    activated = user.activated ? false : true;
    if user.update_attributes({:activated => activated })
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
end
