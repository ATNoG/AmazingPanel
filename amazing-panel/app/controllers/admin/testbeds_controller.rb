class Admin::TestbedsController < TestbedsController
  layout 'admin'
  before_filter :admin_user
  
  def index    
    super()
  end

  def show
    super()
  end
  
  def toggle
    render :nothing => true
  end

end
