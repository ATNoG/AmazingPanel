module Library::LibraryHelper
 
  def add_action(*args, &block)
    html_options = args[2]    
    ("<li class=\"action\">"+link_to(args[0], args[1], html_options)+"</li>").html_safe
  end
end
