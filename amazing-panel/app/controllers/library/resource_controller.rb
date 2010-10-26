class Library::ResourceController < ApplicationController
  layout 'library'  
  
  def get_path_for_library_resource(username, resource, filename)
    return Pathname.new(APP_CONFIG['inventory']).join(resource, filename);
  end
 
  def get_ed_by_user(username, filename)
    return get_path_for_library_resource(username, 'eds', filename);
  end
  
  def get_sysimage_by_user(username, filename)
    return get_path_for_library_resource(username, 'sysimages', filename);
  end
end