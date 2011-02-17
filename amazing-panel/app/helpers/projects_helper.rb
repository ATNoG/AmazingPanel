module ProjectsHelper
  def project_user_path(project, user)
    projects_path.to_s+"/#{project.id}/user/#{user.id}"
  end

  def project_leader_path(project, user)
    projects_path.to_s+"/#{project.id}/user/#{user.id}/leader"
  end
  
  # 'XXX' method returns the opposite
  def project_is_user_assigned?(project, id)
     return (project.user_ids.index(id).nil?)
  end  
 
  def users_action(options={})
    return add_action('Users', users_project_path , options) if can?(:users, Project)
  end  
  
  def assign_action(object, options={})
    return add_image_action(url_params_to(for_action(object, :assign)), 'assign.png', "Assign", options) if can?(:assign, object)
  end  
  
  def make_manager_action(object, options={})
    project = object[0]
    user = object[1]
    return add_image_action(url_params_to(project_leader_path(project, user)), 'star.png', "Make Manager", options.merge({:method=>:put})) if can?(:make_leader, project)
  end

  def assign_user_action(object, options={})
    project = object[0]
    user = object[1]
    return add_image_action(url_params_to(project_user_path(project, user)), 'enable.png', "Assign User", options.merge({:method=>:put})) if can?(:assign_user, project)
  end  
  
  def unassign_user_action(object, options={})
    project = object[0]
    user = object[1]
    return add_image_action(url_params_to(project_user_path(project, user)), 'disable.png', "Unassign User", options.merge({:method=>:delete})) if can?(:unassign_user, project)
  end  
  
  def project_users_empty?(project)
     return project.user_ids.empty?
  end

  def is_user_leader(project, user)
    begin
     @user = Project.find(project.id).users.find(user.id)     
     return (@user.leader == "1")
    rescue
     return false
    end
  end
  
  def project_logo_path(project)
    logo_path = Rails.root.join('images','unknown.png')
    logo = Rails.root.join('public', 'images', 'projects','project-'+project.id.to_s)
    if logo.exist?      
      logo_path = logo
    end    
    return '/'+logo_path.relative_path_from(Rails.root.join('public'))
  end

  def project_logo_path_for(project)
    return Rails.root.join('public','images','projects','project-'+project.id.to_s)
  end

  def autocomplete_line
    return "<li><p>${user.name},${user.email}</p></li>"
  end

  def user_unassigned_table_line_template(project_id)
    return ("<tr>"+
    "<td><a href=\"/users/${user.id}\">${user.id}</a></td>"+
    "<td class=\"name-cell\"><a href=\"/users/${user.id}\">${user.name}</a></td>"+
    "<td class=\"email-cell\">${user.email}</td>"+
    "<td><div class=\"table-actions\">"+
      "<a href=\"/workspaces/#{project_id}/user/${user.id}\" class=\"action\" data-method=\"put\" rel=\"nofollow\" original-title=\"Assign ${user.name} to project\"><img alt=\"Disable\" height=\"16\" src=\"/images/enable.png\" width=\"16\"></a>"+
    "</div></td>"+
    "</tr>")
  end
  
  def user_assigned_table_line_template(project_id)
     return ("<tr>"+
          "<td><a href=\"/users/${user.id}\">${user.id}</a></td>"+
          "<td class=\"name-cell\"><a href=\"/users/${user.id}\">${user.name}</a></td>"+
          "<td class=\"email-cell\" >${user.email}</td>"+
          "<td><div class=\"table-actions\">"+        
            "{{if user.leader==0}}"+
              "<a href=\"/workspaces/#{project_id}/user/${user.id}\" class=\"action\" data-method=\"put\" rel=\"nofollow\" original-title=\"Make ${user.name} manager project\"><img alt=\"Make Manager\" height=\"16\" src=\"/images/star.png\" width=\"16\"></a>"+
            "{{/if}} "+          
            "<a href=\"/workspaces/#{project_id}/user/${user.id}\" class=\"action\" data-method=\"delete\" rel=\"nofollow\" original-title=\"Unassign ${user.name} to project\"><img alt=\"Disable\" height=\"16\" src=\"/images/disable.png\" width=\"16\"></a>"+
          "</div></td>"+"</tr>")
  end
end
