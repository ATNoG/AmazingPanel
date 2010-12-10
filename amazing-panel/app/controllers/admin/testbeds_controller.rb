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
    @node = Node.find(params[:node_id])
    @id = @node.id
    @status = OMF::GridServices.testbed_node_toggle(params[:id], @id)
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
end
