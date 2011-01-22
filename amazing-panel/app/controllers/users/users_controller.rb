class Users::UsersController < Library::ResourceController  
  before_filter :authenticate  
  layout 'application'

  def resource()
    return User
  end
  
  def resource_find_all()
    return User.all
  end
  
  def resource_find(id)
    return User.find(id)
  end
  
  def resource_new(model=nil)
    if model.nil?
      return User.new
    else
      return User.new(model)
    end
  end 
  
  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])    
  end

  def update
    @user = User.find(params[:id])    
    if @user.update_attributes(params[:user])
      flash[:success] = 'Profile updated.'
      redirect_to(user_path(@user))
    end  
  end


end
