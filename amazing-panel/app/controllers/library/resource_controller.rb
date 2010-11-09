class Library::ResourceController < ApplicationController
  layout 'library'
   
  def resource_find_all
  end

  def resource_find(id)
  end
  
  def resource_new(model = nil)
  end
  
  def resource()
  end
  
  def get_path_for_library_resource(username, resource, filename)
    return Pathname.new(APP_CONFIG['inventory']).join('users', username, resource, filename);
  end
 
  def get_ed_by_user(username, filename)
    return get_path_for_library_resource(username, 'eds', filename);
  end
  
  def get_sysimage_by_user(username, filename)
    return get_path_for_library_resource(username, 'sysimages', filename);
  end
  
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

  protected
    def add_filters(filters)
      controller = self.request.parameters[:controller]      
      if filters.class.to_s == "Fixnum"
	  session[controller][:filters].delete(filters)    
      elsif filters.nil?	
	if session[controller][:filters].nil? == false
	  session[controller][:filters].clear()	  
	end	
      elsif filters.length>0 	
	if (session[controller][:filters].nil?)
	  session[controller][:filters] = Hash.new
	end	
	filters.each do |_f|
	  if session[controller][:filters].index(_f).nil?
	    _id = session[controller][:filters].length + 1
	    session[controller][:filters][_id] = _f	    
	  end
	end
      end
    end
end