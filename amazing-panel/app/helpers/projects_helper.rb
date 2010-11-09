module ProjectsHelper
  def project_user_path(project, user)
    "/projects/#{project.id}/user/#{user.id}"
  end

  def project_leader_path(project, user)
    "/projects/#{project.id}/user/#{user.id}/leader"
  end
  
  def project_is_user_assigned?(project, id)
     return (project.user_ids.index(id).nil?)
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

end
