module Users::UsersHelper
  def generate_projects(user)
    projects = ProjectsUsers.where(:user_id => user.id)
    _projects = ""
    projects.each do |p|
      _p = Project.find(p.project_id)
      _name = link_to(_p.name, project_path(_p)) + (p.leader? ? image_tag('star.png', :class=>"leader-badge-profile") : "")
      li = content_tag(:li, image_tag(project_logo_path(_p)) + _name, :class => "project")
      _projects += li.html_safe
    end    
    ul = content_tag(:ul, _projects.html_safe)
    return ul.html_safe
  end
 
  def activate_user_action(object, options={})
    user = object
    if can?(:activate, user)
      if user.activated?
       return add_image_action(user_activate_path(:user_id => user.id), 'disable.png', "Deactivate", 
                               options.merge({:method=>:put, "original-title" => "Deactivate account"})) 
      else 
       return add_image_action(user_activate_path(:user_id => user.id), 'enable.png', "Activate", 
                               options.merge({:method=>:put, "original-title" => "Activate account"}))
      end
    end 
  end  

end
