class PagesController < ApplicationController
  
  respond_to :html, :js
  def index
    %w{ models controllers }.each do |dir|
      path = File.join(File.dirname(__FILE__), 'app', dir)      
      puts path
    end
  end
end
