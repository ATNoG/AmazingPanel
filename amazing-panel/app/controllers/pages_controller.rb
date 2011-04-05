class PagesController < ApplicationController
  respond_to :html, :only => [:index]
  respond_to :js, :only => [:application] 
  respond_to :css, :only => [:custom]
  
  def index 
    @news = Array.new()
    NEWS_SOURCES.each do |source|
      url = URI.parse(source)
      p = Net::HTTP::Get.new(url.path) 
      http = Net::HTTP.new(url.host, url.port)
      body = http.request(p).body
      content = ActiveSupport::JSON.decode(body)
      unless content.blank?
        ns = content.take(5).uniq().collect! {|n| 
          { :title => n['title'], :created_on => n['created_on'] }
        }
        @news = @news.concat(ns)
      end
    end
  end
  
  def application
    @c = params[:c]
    @a = params[:a]
    @p= params[:p]
  end
  
  def custom
    render 'custom.css', :content_type => 'text/css'
  end
end
