require 'omf'

class Admin::TestbedsController < TestbedsController
  include OMF::GridServices
  include Admin::TestbedsHelper

  layout 'admin'

  before_filter :admin_user
  
  def index
    super()
  end

  def show
    super()
  end
  
  def node_toggle
    super()
  end
  
  def node_info
    super()
  end
end
