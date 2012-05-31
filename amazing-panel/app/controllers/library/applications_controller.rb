require 'ostruct'

class Library::ApplicationsController < Library::OEDLController

  def index
    repository = ScriptHandler.scanUserRepository(current_user.username)
    @apps = []
    repository.each do |uri, app|
      @apps.push(build_app(uri, app))
    end
  end

  def show
    oedl_app = oedl_filter(definition(params[:id]))
    @app = build_app(oedl_app[0], oedl_app[1])
    @code = code(oedl_app[0])
  end

  def new
  end

  def edit
    oedl_app = oedl_filter(definition(params[:id]))
    @app = build_app(oedl_app[0], oedl_app[1])
    @code = code(oedl_app[0])
  end

  def update
		if File.extname(params[:package].original_filename) != ".tar"
    	flash["error"] = t("amazing.applications.must_be_tar_file")
    	redirect_to edit_application_path(:id => params[:id])
			return;
		end

    uri = user_repository(params[:id])
    ScriptHandler.writeDefinition(uri, params[:code], params[:package])
    
		flash["success"] = t("amazing.applications.updated")
    redirect_to application_path(:id => params[:id])
  end

  def destroy
    uri = user_repository(params[:id])
    Rails.logger.debug "Removing application"
    #ScriptHandler.removeDefinition(uri)
    redirect_to applications_path
  end

  private

  def oedl_filter(repository)
    return repository.properties[:repository][:apps].to_a.first
  end

  def build_app(uri, happ)
    return OpenStruct.new({
      :uri => uri,
      :name => happ[:name],
      :shortDescription => happ['shortDescription'],
      :description => happ['description'],
      :path => happ['path']
    })
  end

end
