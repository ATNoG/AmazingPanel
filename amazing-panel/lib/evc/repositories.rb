module EVC
  class Repository
    attr_accessor :id, :name, :user, :current, :branches

    def initialize(id, user)      
      @id = id    
      @user = user
      @current = EVC::Branch.new(@id, "master", user.username)      
      refresh_branches
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
      master_branch = EVC::Branch.new(@id, "master", @user.username)
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

    def changes(author=@user.username)
      changes = Hash.new()
      @branches.each do |n, b|
        changes[n] = b.commits(author)
      end
      return changes
    end
    
    def clone_branch(name, parent="master")
      keys = @branches.keys
      return false if (!keys.include?(parent) or keys.include?(name))
      Rails.logger.debug "#{name}, parent=#{parent}"
      branch = EVC::Branch.new(@id, name, @user.username)
      branch.clone_branch(parent, "Branch from #{parent}")      
      refresh_branches
      return true
    end

    def change_branch(name)
      @current = @branches[name] if @branches.keys.include?(name)
      return @current
    end
    
    private
    def refresh_branches()
      @branches = list_branches()
    end
    # List all branches
    # Returns an array of Branches
    def list_branches()
      set = {}

      # Add only directories
      # discarding '.' and '..' dir entries
      blacklist = [".", ".."]
      Dir.foreach(branches_path()) { |e|
        unless blacklist.include?(e)
          set[e] = EVC::Branch.new(@id,e,user.username) if File.directory?("#{branches_path()}/#{e}")
        end
      }
      return set
    end
  end
end

