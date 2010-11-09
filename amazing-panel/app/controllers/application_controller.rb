class ApplicationController < ActionController::Base
  protect_from_forgery
  
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
    
    def action_image()
      
    end
end
