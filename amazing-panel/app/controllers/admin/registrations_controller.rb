class Admin::RegistrationsController < Users::RegistrationsController
  prepend_before_filter :admin_user, :only => [:destroy, :index]
  layout 'admin'
end
