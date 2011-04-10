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
    
    def exists?()
      rp_f = File.directory?(repository_path)
      b_f = File.directory?(branches_path)
      return rp_f && b_f
    end

    def init(resource_map)
      experiment = Experiment.find(@id)
      
      # valid resource map data
      unless resource_map.has_key?('resources')
        return false
      end

      # checks if branches already exists 
      if File.directory?(branches_path())
        return false
      end

      # create if repository does not exist
      unless File.directory?(repository_path())
        Dir.mkdir(repository_path())
      end

      # Create the branches repository
      Dir.mkdir(branches_path())

      # Create 'master' Repository
      master_branch = EVC::Branch.new(@id, "master", @user.username)
      ret = master_branch.new_branch("Main branch of ##{@id}")

      # Fetchs experiment information
      code = experiment.ed.code

      # Commits the master with the necessary information"
      ret = master_branch.commit_branch("Initial commit", code, resource_map)
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
      unless exists? then return [] end
      set = {}

      # Add only directories
      # discarding '.' and '..' dir entries
      blacklist = [".", ".."]
      Dir.foreach(branches_path()) { |e|
        unless blacklist.include?(e)
          if File.directory?("#{branches_path()}/#{e}")
            set[e] = EVC::Branch.new(@id,e,user.username)
          end
        end
      }
      return set
    end
  end
end

