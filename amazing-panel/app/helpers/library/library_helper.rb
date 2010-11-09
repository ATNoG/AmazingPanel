module Library::LibraryHelper
 
  def add_action(*args, &block)
    controller = args[2]
    html_options = args[3]
    classes = ["action"]
    if is_active_by_controllers?(controller)
      classes.push("active")
    end
    li = content_tag(:li, link_to(args[0], args[1], html_options), :class => classes)
    return li.html_safe
  end
end
