module Users::UsersHelper
  def generate_projects(user)
    projects = ProjectsUsers.where(:user_id => user.id)
    _projects = ""
    projects.each do |p|
      _p = Project.find(p.project_id)
      li = content_tag(:li, image_tag(project_logo_path(_p)) + link_to(_p.name, project_path(_p)), :class => "project")
      _projects += li.html_safe
    end    
    ul = content_tag(:ul, _projects.html_safe)
    return ul.html_safe
  end
end
