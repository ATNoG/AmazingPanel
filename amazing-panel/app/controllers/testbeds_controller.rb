require 'net/http'

class TestbedsController < ApplicationController 
  include TestbedsHelper
  layout 'general'  
  respond_to :html, :js  
  before_filter :properties, :only => [:show]

  def index
    @testbeds = Testbed.all
  end
  
  def show
    @testbed = Testbed.find(params[:id])    
    @nodes = @@properties["positions"]
    if params[:timestamp].nil? == false
      @status = statusAll()
      expires_in 5.seconds, :private => false, :public => true
      current_timestamp = Integer(Time.now.strftime("%s"))
      past_timestamp = Integer(params['timestamp'])
      @interval = current_timestamp - past_timestamp
    end
  end
  
  protected 
    def properties
      @@properties = testbed_properties_for(params[:id])["testbed"]
    end

    def statusAll()
      
      #data = File.new('tmp/nodes.json','r').readlines().to_s
      #status = ActiveSupport::JSON.decode(data)      
      #return status
      #req = Net::HTTP::Get.new(@@path + 'power/status')
      #resp = @@http.request(req)
      #status = ActiveSupport::JSON.decode(resp.body.gsub("'", "\""))
      #puts status
      #status.delete("type")
      #return status
      return ogscmc_ws_invoke("status", params)
    end

    def ogscmc_ws_invoke(action, args, controller="power") 
      if (!@@properties.nil? and !args[:id].nil?)
        id = args[:id]
        @@http = Net::HTTP.new(@@properties["server_url"])
        @@path = @@properties["server_path"]
        path = "#{@@path + controller}/#{action}"+(!args[:node_id].nil? ? "/#{args[:node_id]}" : "")
        req = Net::HTTP::Get.new(path)
        resp = @@http.request(req)
        ret = ActiveSupport::JSON.decode(resp.body.gsub("'", "\""))
        ret.delete("type")
        return ret
      end
    end
end
