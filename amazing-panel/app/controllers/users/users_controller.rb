class Users::UsersController < ApplicationController
  #include Devise::Controllers::InternalHelpers  
  
  before_filter :authenticate  
  
  def show
    @user = User.find(params[:id])
  end
  
  def index
    @users = User.where(["id != ?", current_user.id])
    render :action => :index
  end
end
