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
      permission_denied(new_user_session_path) unless !current_user.nil?
      unless current_user.nil?
        permission_denied(new_user_session_path) unless current_user.admin?
      end 
    end

    def permission_denied(path)
      redirect_to(path, :notice => "You don't have permission to modify this resource")
    end
end
