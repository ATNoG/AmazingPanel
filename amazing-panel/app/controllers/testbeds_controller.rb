require 'net/http'
require 'omf'

class TestbedsController < ApplicationController 
  include OMF::GridServices
  layout 'general'  
  respond_to :html, :js, :json

  def index
    @testbeds = Testbed.all
  end
  
  def show
    @testbed = Testbed.find(params[:id])
    unless ["js", "html"].include?(params[:format])
      @nodes = OMF::GridServices.testbed_status(params[:id])
    end

    if params[:timestamp].nil? == false
      @nodes = OMF::GridServices.testbed_status(params[:id])
      expires_in 5.seconds, :private => false, :public => true
      current_timestamp = Integer(Time.now.strftime("%s"))
      past_timestamp = Integer(params['timestamp'])
      @interval = current_timestamp - past_timestamp
    end

    respond_with(@nodes)
  end
end
