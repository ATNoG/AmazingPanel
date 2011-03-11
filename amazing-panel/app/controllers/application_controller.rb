class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :set_locale
  rescue_from ActionController::RoutingError, :with => :route_not_found

  rescue_from CanCan::AccessDenied do |exception|  
    flash[:error] = t(:permission_denied)
    redirect_to(root_path)
  end 

  private

    def set_locale
      I18n.locale = params[:locale]
    end
  
    def route_not_found
      render "shared/404", :status => :not_found
    end
  
    def authenticate
      session['return_url'] = request.url
      redirect_to new_user_session_path, :notice => t("devise.failure.unauthenticated") unless user_signed_in?
    end

    def after_sign_in_path_for(resource_or_scope)
      url = session['return_url']
      if url.nil?
        root_path
      else
        session['return_url']        
      end      
    end
    
    def after_sign_out_path_for(resource_or_scope)
      session['return_url'] = ""
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
      redirect_to(path, :notice => t(:permission_denied))
    end

    def save_previous_path
      session[:previous] = self.request.headers['PATH_INFO']
    end
end
