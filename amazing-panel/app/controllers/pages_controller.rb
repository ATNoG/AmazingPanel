class PagesController < ApplicationController
  
  respond_to :html, :js, :css
  def index
  end
  
  def application
    @c = params[:c]
    @a = params[:a]
    @p= params[:p]
  end
  
  def custom
  end
end
