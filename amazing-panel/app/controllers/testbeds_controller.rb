class TestbedsController < ApplicationController
  include TestbedsHelper
  
  layout 'general'  
  respond_to :html, :js  
  
  def index
    @testbeds = Testbed.all
  end
  
  def show
    @testbed = Testbed.find(params[:id])    
    @nodes = testbed_properties_for(@testbed)
    
    expires_in 5.seconds, :private => false, :public => true
    @status = get_nodes_status()
    current_timestamp = Integer(Time.now.strftime("%s"))
    past_timestamp = Integer(params['timestamp'])
    @interval = current_timestamp - past_timestamp
  end
  protected

  def testbed_properties_for(testbed)
    return YAML.load_file("#{Rails.root}/inventory/testbeds/#{testbed.id}.yml")
  end
end