require 'net/http'
require 'omf'

class TestbedsController < ApplicationController
  include OMF::GridServices
  layout 'general'
  respond_to :html, :js, :json
  load_and_authorize_resource :except => [:index, :show]

  def index
    @testbeds = Testbed.all
  end

  def show
    @testbeds = Testbed.all
    @testbed = Testbed.find(params[:id])
    service = OMF::GridServices::TestbedService.new(@testbed.id)
    @has_map = service.has_map
    unless ["js", "html"].include?(params[:format])
      @nodes = service.mapping();
    end

    unless params[:timestamp].nil?
      @nodes = OMF::GridServices.testbed_status(params[:id])
      expires_in 5.seconds, :private => false, :public => true
      current_timestamp = Integer(Time.now.strftime("%s"))
      past_timestamp = Integer(params['timestamp'])
      @interval = current_timestamp - past_timestamp
    end
    flash['info flash'] = t("amazing.testbed.status", :interval => 5)
    respond_with(@nodes)
  end

  def node_toggle_maintain
    @node = Node.find(params[:node_id])
    @id = @node.id
    @status = OMF::GridServices.testbed_node_maintain(params[:id], @id)
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
