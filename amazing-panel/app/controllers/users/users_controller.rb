class Users::UsersController < ApplicationController
  #include Devise::Controllers::InternalHelpers  
  
  before_filter :authenticate, :only => [:show, :index, :destroy]
  before_filter :admin_user,   :only => [:index, :destroy]
  
  def show
    @user = User.find(params[:id])
  end
  
  def index
    @users = User.where(["id != ?", current_user.id])
    render :action => :index
  end
  
  def activate
    user = User.find(params[:user_id]);
    activated = user.activated ? true : false;
    if user.update_attributes({:activated => activated })
      redirect_to users_path
    end
  end
  
  def destroy
    @user = User.find(params[:id])
    if @user.destroy
      flash['notice'] = "Successfully deleted User."
      redirect_to root_path
    end
  end

  private
    def authenticate
      redirect_to new_user_session_path, :notice => "Please sign in to access this page." unless user_signed_in?
    end
    
    def correct_user
      @user = User.find(params[:id])
      redirect_to(root_path) unless current_user?(@user)
    end
    
    def admin_user
      redirect_to(root_path) unless current_user.admin?
    end
end
