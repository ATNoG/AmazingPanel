require 'fileutils'

class Users::RegistrationsController < Devise::RegistrationsController
  prepend_before_filter :authenticate_scope!, :only => [:edit, :update, :destroy, :index]
  
  # POST /resource/sign_up
  def create
    build_resource

    if resource.save
      #puts Rails.root.class
      set_flash_message :notice, "Your account has been created! Wait until further activation."
      redirect_to(:root)
    else
      clean_up_passwords(resource)
      render_with_scope :new
    end
  end
  
  def require_no_authentication
    return true
  end
  
end