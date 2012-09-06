class Library::LibraryController < ApplicationController
  layout 'library'
  before_filter :authenticate
  
  def index
  end
end
