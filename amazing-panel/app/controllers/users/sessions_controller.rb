class Users::SessionsController < Devise::SessionsController
  def create
    user = User.where(:username => params[:user][:username]).first;
    puts user.inspect
    if !user.nil?
      if user.activated == false
	set_flash_message :notice, "Your account isn't activated yet."
	redirect_to(:root);
      else
	super
      end    
    else      
      redirect_to new_user_session_path, :notice => "Wrong username."
    end
  end
end
