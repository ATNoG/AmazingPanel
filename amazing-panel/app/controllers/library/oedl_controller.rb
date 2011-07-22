class Library::OEDLController < ApplicationController
  layout 'library'
  respond_to :html

  include OMF::Experiments
  include OMF::Experiments::OEDL

  def code(uri)
    path = Pathname.new("#{APP_CONFIG['oedl_repository']}/#{uri.gsub(/[:]/,'/')}.rb")  
    return IO::read(path)
  end

  def user_repository(name)
    return "#{ScriptHandler.uri_for(current_user.username)}#{name}"
  end

  def definition(name)
    return ScriptHandler.getDefinition(user_repository(name))
  end
end
