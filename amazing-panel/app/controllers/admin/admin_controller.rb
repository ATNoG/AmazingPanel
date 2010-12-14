class Admin::AdminController < Library::LibraryController
  before_filter :admin_user
  layout 'admin'
  def index
  end
end
