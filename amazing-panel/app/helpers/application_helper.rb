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
  
  def top_is_active(controller, action)
    if is_active?(controller, action)
      return "top-active";
    end
  end

  def top_is_active_by_controller(controller)
    if is_active_by_controller?(controller)
      return "top-active";
    end
  end  

  def top_is_active_by_controllers(controllers)
    if is_active_by_controllers?(controllers)
      return "top-active";
    end
  end  
  
  def omni_is_active(controller, action)
    if is_active?(controller, action)
      return "omni-active";
    end
  end
end
