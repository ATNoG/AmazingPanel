module ApplicationHelper
  def is_active?(controller, action)
    (self.request.parameters[:controller] == controller) && (self.request.parameters[:action] == action)
  end
  
  def is_active_by_controller?(controller)
    (self.request.parameters[:controller] == controller)
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
  def omni_is_active(controller, action)
    if is_active?(controller, action)
      return "omni-active";
    end
  end

end
