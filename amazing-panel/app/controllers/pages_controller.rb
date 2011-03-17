class PagesController < ApplicationController
  respond_to :html, :only => [:index]
  respond_to :mobile, :only => [:index]
  respond_to :js, :only => [:application] 
  respond_to :css, :only => [:custom]
  
  def index     
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
