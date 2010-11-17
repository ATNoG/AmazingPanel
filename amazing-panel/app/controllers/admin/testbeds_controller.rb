class Admin::TestbedsController < TestbedsController
  include Admin::TestbedsHelper

  layout 'admin'

  before_filter :admin_user
#  prepend_before_filter :setHTTPEnvironment, :properties, :only => [:node_toggle]    
#  prepend_before_filter :setHTTPEnvironment, :properties, :admin_user, :only => [:show]
#  prepend_before_filter :setHTTPEnvironment, :properties, :admin_user, :only => [:node_toggle]    

  def index    
    super()
  end

  def show
    super()
  end
  
  def node_toggle
    properties
    @node = Node.find(params[:node_id])
    @id = @node.id
    @status = toggle()
  end
  
  def node_info
    @node = Node.find(params[:node_id])
    @motherboard = Motherboard.find(@node.motherboard_id)
    @data = Hash.new()
    @data["Control IP: "] = @node.control_ip
    @data["Control MAC Address: "] = @node.control_mac 
    @data["Hostname: "] = @node.hrn
    @data["Motherboard Manufacturer Serial: "] = @motherboard.mfr_sn
    @data["CPU: "] = "#{@motherboard.cpu_type}@#{@motherboard.cpu_hz * 0.001} KHz"
    
    respond_to do |format|
      format.js
    end
  end

  private

    def toggle      
      return 'run'
      #return ogscmc_ws_invoke("toggle", params.merge!({ :node_id => params[:node_id] }))
    end
end
