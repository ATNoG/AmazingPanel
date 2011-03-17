module EVC
  class Repository
    attr_accessor :id, :name, :user, :current

    def initialize(id, user)      
      @id = id    
      @user = user
      @current = EVC::Branch.new(@id, "master", user.username)
    end

    def repository_path()
      return "#{APP_CONFIG['inventory']}/experiments/#{@id}"
    end

    def branches_path()
      return "#{repository_path}/branches"
    end
    
    def init(resource_map)
      # checks if branches already exists 
      if File.directory?(branches_path())
        return false
      end

      # Create the branches repository
      Dir.mkdir(branches_path())

      # Create 'master' Repository
      master_branch = EVC::Branch.new(@id, "master", user.username)
      ret = master_branch.new_branch("Main branch of ##{@id}")

      # Fetchs experiment information
      experiment = Experiment.find(@id)
      code = experiment.ed.code
      rm = {
        "resources" => resource_map
      }
      
      # Commits the master with the necessary information"
      ret = master_branch.commit_branch("Initial commit", code, rm)
      return ret[0]
    end
    
    def change_branch(name)
      @current = Branch.new(@id, name, user.username)      
    end
    
    # List all branches
    # Returns an array of Branches
    def list_branches()
      list = []

      # Add only directories
      # discarding '.' and '..' dir entries
      blacklist = [".", ".."]
      Dir.foreach(branches_path()) { |e|
        unless blacklist.include?(e)
          list << EVC::Branch.new(@id,e,user.username) if File.directory?("#{branches_path()}/#{e}")
        end
      }
      return list
    end
  end
end

