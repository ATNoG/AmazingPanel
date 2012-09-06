module ApplicationHelper
  
  def current_user_page()
    if (self.request.headers['PATH_INFO'] == '/users/'+ current_user.id.to_s)
      return "omni-active";
    end
  end
  
  def is_active?(controller, action)
    (self.request.parameters[:controller] == controller) && (self.request.parameters[:action] == action)
  end
  
  def is_active_by_controller?(controller)
    (self.request.parameters[:controller] == controller)
  end
  
  def is_active_by_controllers?(controllers)
    for c in controllers:
      if (self.request.parameters[:controller] == c)
    	return true
      end
    end
    return false
  end  

  def is_active(context)    
    ctx_controller = context[:controller]
    ctx_action = context[:action]
    flags = Hash.new()   
    flags[:single_controller] = (!ctx_controller.nil? and ctx_controller.class == String)
    flags[:multi_controller] = (!ctx_controller.nil? and ctx_controller.class == Array)
    flags[:has_action] = !ctx_action.nil?
    if flags[:single_controller] and flags[:has_action] 
      return is_active?(ctx_controller, ctx_action) ? true : false
    end
    if flags[:single_controller] 
      return is_active_by_controller?(ctx_controller) ? true : false
    end
    if flags[:multi_controller] 
      return is_active_by_controllers?(ctx_controller) ? true : false
    end
    return false
  end

  def clear
    return content_tag(:div, nil, :class => "clear")
  end

  def url_params_to(*args)
    object = args.class == Array ? args[0] : args
    p = args[1] if args.class == Array
    if args.length == 1      
      return url_for(args[0])    
    else
      return "#{url_for([:new,object])}?#{p.to_query}" if args.length == 2
    end
  end

  def for_action(object, action)
    return (object.class == Array ? [action, object[0]] : [action, object])
  end

  def new_action(args, options={})
    if args.class == String      
      url = args
    else
      object = args.class == Array ? args[0] : args
      p = args[1] if args.class == Array
      url = "#{url_for([:new,object.name.underscore.to_sym])}"
      url = args.class == Array ? "#{url}?#{p.to_query}" : url
    end
    if options[:highlight].nil?
      options[:highlight] = true
    end
    return add_image_action(url, 'add.png', "New", options) if can?(:create, object)
  end
  
  def back_action(link, options={})
    return add_image_action(link, 'back.png', "Back", options)
  end
  
  def delete_action(object, options={})
    url = object.class == String ? object : url_params_to(object)
    return add_image_action(url, 'remove.png', "Delete", options.merge!({ :method => 'delete'})) if can?(:destroy, object)
  end

  def edit_action(object, options={})
    url = object.class == String ? object : url_params_to(object)
    return add_image_action(url+'/edit', 'edit.png', "Edit", options) if can?(:update, object)
  end

  def add_image_action(link, src, text=nil, options={})
    has_text = options[:text]
    text = (has_text == false) ? "" : (" "+text).html_safe
    return add_action(image_tag(src, {:width => 16, :height => 16}) + text,
                      link, {}, {:class => "action"}.merge!(options))
  end
  
  def add_action(name, link, *args)
    add_application_action(name, link, args)
  end
  
  def add_nav_action(name, link, *args)
    args[0][:prefix] = "top";
    add_application_action(name, link, args)
  end

  def add_omni_action(name, link, *args)
    args[0][:prefix] = "omni";
    add_application_action(name, link, args)
  end

  def add_application_action(name, link, *args)
    context = args[0][0]
    html_options = args[0][1]
    prefix = context.nil? ? nil : context[:prefix]
    item_name = (prefix.nil? ? "action" : prefix+"-item")
    item_active = (prefix.nil? ? "active" : prefix+"-active")    
    if html_options.nil? then html_options = Hash.new end

    html_action_class = html_options[:action_class]
    html_options[:action_class] = html_action_class.nil? ? [item_name] : html_action_class | [item_name]
    
    if !context.nil?
      html_options[:action_class].push(is_active(context) ? item_active : "")
    end

    action_classes = html_options.delete(:action_class)
    unless html_options[:highlight].nil? and !html_options[:highlight]
      action_classes.push("highlight")
    end
    ret = content_tag(:li, link_to(name, link, html_options), :class => action_classes)
    if html_options[:link] == true
      ret = link_to(name, link, html_options)
    end
    return ret.html_safe
  end  

  def toolbar(&block)
    if block_given?
      ul = content_tag(:ul, with_output_buffer(&block), :id => "toolbar-action-list")
      return content_tag(:div, ul, :id => "toolbar")
    end
  end

  def sub_toolbar(&block)
    if block_given?
      ul = content_tag(:ul, capture(&block), :id => "toolbar-action-list")
      return content_tag(:div, ul, :id => "sub-toolbar")
    end
  end

  def navigator()
  end

  def progress_bar()
    span = content_tag(:span, "0%", :class => "progress_text")
    bar = content_tag(:div, "", :class => "progress_bar", :style => "width:0%")
    progress_container = content_tag(:div, span+bar, :class=>"progress-container")
    return progress_container
  end
end
