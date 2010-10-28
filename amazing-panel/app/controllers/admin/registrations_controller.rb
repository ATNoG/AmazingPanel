class Admin::RegistrationsController < Users::RegistrationsController
  before_filter :admin_user
  layout 'admin'
end
