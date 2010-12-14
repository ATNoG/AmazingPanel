class Library::ResourceController < ApplicationController
  layout 'library'
  respond_to :html
  before_filter :authenticate
  append_before_filter :has_resource_permission, :only => [:update, :destroy, :edit]
  append_before_filter :filter_resources, :only => [:index]

  def resource_find_all
  end

  def resource_find(id)
  end
  
  def resource_new(model = nil)
  end
  
  def resource()
  end

  def resource_group()
  end

  def get_path(resource, extension="")
    return Pathname.new(APP_CONFIG['inventory']).join('users', resource.user.username, 
                        resource_group(), "#{resource.id}.#{extension}");
  end
 
  #def get_ed_by_user(username, filename)
    #return get_path_for_library_resource(username, 'eds', filename);
  #end
  
  #def get_sysimage_by_user(username, filename)
    #return get_path_for_library_resource(username, 'sysimages', filename);
  #end
  
  def order_by(column, order)    
    return resource().order(column.to_s + " " + order)
  end
  
  def filter_params(params)
    controller = self.request.parameters[:controller]
    if (/clear(:\d+)?/.match(params[:filter]))
      if (params[:filter] == "clear")      
	if params[:value].nil?
	  return nil 	
	end
	return params[:value].to_i
      end
    end
    filter = params[:filter];
    if filter == "field"      
      ret = Array.new    
      ret.push({ :field =>  params[:field], :op => params[:op], :value => params[:value] });
      return ret
    end
  end
  
  def filter(args)
    controller = self.request.parameters[:controller]

    resources = nil
    if args[:filter].nil? == false
      filters = filter_params(args)
      add_filters(filters)
      puts "filters:"+session[controller][:filters].inspect
    end
    
    if session[controller].nil? or session[controller][:filters].length == 0            
      session[controller] = Hash.new
      session[controller][:filters] = Hash.new
      @filters = session[controller][:filters]
      return resource_find_all()
    end
    
    session[controller][:filters].each do |k,f|
      begin
	m = resource().method(f[:op])
	puts m.inspect
	if resources.nil? 
	  resources = m.call(f[:field], f[:value])
	else	  
	  _r = m.call(f[:field], f[:value])	  
	  tmp = Array.new	  
	  resources.each do |r|
	    if _r.index(r).nil? == false
	      tmp.push(r)
	    end
	  end	 
	  if tmp.length > 0
	    resources = tmp
	  else tmp.length == 0
	    resources = nil
	  end
	end
      rescue
	@error = "Invalid Filter"
      end
    end
    @filters = session[controller][:filters]
    return resources
  end

  def index 
    current_page = params[:page]
    if current_page.nil?
      current_page = '1'
    end
    
    if @resources.nil? == false
      @resources = @resources.paginate(:page => current_page)
    end

    unless @error.nil?
      @error = "Invalid Filter"
    end
  end

  protected
    def add_filters(filters)
      controller = self.request.parameters[:controller]
      session_filters = session[controller][:filters]
      if filters.class.to_s == "Fixnum"
	    session_filters.delete(filters)    
      elsif filters.nil?	
    	if session_filters.nil? == false
    	  session_filters.clear()	  
    	end	
      elsif filters.length>0 	
    	if session_filters.nil?
    	  session_filters = Hash.new
    	end	
    	filters.each do |_f|
    	  if session_filters.index(_f).nil?
    	    _id = session_filters.length + 1
    	    session_filters[_id] = _f	    
    	  end
    	end
      end
      session[controller][:filters] = session_filters
    end


    def filter_resources
      unless params[:filter].nil?
        redirect_to url_for(:action => 'index')
      end    
      @resources = filter(params)
    end

    # Only the owner or the admins can write/edit resource
    def has_resource_permission()
      resource = resource().find(params[:id])
      unless (current_user.admin? or current_user == resource.user)
        return head(:forbidden)
      end
      return true
    end

    def write_resource(resource, content, extension="")
      path = get_path(resource, extension)
      File.open(path, 'w') do |file|
        file.write(content)
      end
    end
    
    # For now everyone has read permissions
    def read_resource(resource, content, extension="")
      path = get_path(resource, extension)
      return File.open(path, 'r')
    end

    def delete_resource(resource, extension="")
      path = get_path(@ed, extension)
      File.delete(path.to_s)
    end
end
