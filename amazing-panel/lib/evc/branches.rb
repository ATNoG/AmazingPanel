module EVC
  class Branch
    attr_accessor :id, :name, :user, :commit, :info

    # Initialize a new Branch class instance
    # Parameters: id(String), name (String), user (String)
    def initialize(id, name, user)
      @id = id
      @name = name
      @user = user
      @commit = change_branch_commit()
    end

    def branches_path()
      return "#{APP_CONFIG['inventory']}/experiments/#{@id}/branches"
    end

    def branch_path(name=nil)
      name = @name if name.nil?
      return "#{branches_path()}/#{name}"
    end

    def branch_info_path(name=nil)
      name = @name if name.nil?
      return "#{branch_path(name)}/.info"
    end

    def branch_resource_map_path()      
      return "#{branch_path()}/objects/#{@commit}/resource_map.yml"
    end
    
    def branch_code_path()      
      return "#{branch_path()}/objects/#{@commit}/code.rb"
    end

    def create_changelog_entry(message)
      return {"author" => @user, "message" => message}
    end

    def load_branch_info
      return YAML.load_file(branch_info_path())
    end

    def save_branch_info(branch_info)
      File.open("#{branch_info_path()}", 'w') {|f|
        f.write(branch_info.to_yaml)
      }
    end

    # Creates a new branch
    # Parameters: description (String)
    def new_branch(description)
      # Duplicated 'name' branch?
      if (File.directory?(branch_path()))
        return [false, "Branch #{@name} already exists"]
      end

      # Create the branch directory
      Dir.mkdir(branch_path())
      Dir.mkdir("#{branch_path()}/objects/")
      Dir.mkdir("#{branch_path()}/runs/")

      # Branch info YAML file
      branch_info = Hash.new
      branch_info[@name] = {
        "description" => description, 
        "author" => @user, 
        "runs" => 0, 
        "failures" => 0, 
        "changelog" => {
          Time.now.to_i => create_changelog_entry("Init branch") 
        } 
      }
      save_branch_info(branch_info)
      return [true, "Branch #{name} created successfully"]
    end

    # Commit changes done to the branch
    # Parameters: message (String), code (String), resource_map (Hash)
    def commit_branch(message, code, resource_map)
      timestamp = Time.now.to_i
      Dir.mkdir("#{branch_path()}/objects/#{timestamp}")

      # Write 'code' to file
      File.open("#{branch_path()}/objects/#{timestamp}/code.rb", 'w') {|f|
        f.write(code)
      }

      # Write 'resource_map' to file
      File.open("#{branch_path()}/objects/#{timestamp}/resource_map.yml", 'w') {|f|
        f.write(resource_map.to_yaml)
      }

      # Update changelog
      branch_info = YAML.load_file(branch_info_path())
      branch_info[@name]['changelog'][timestamp] = create_changelog_entry(message)
      save_branch_info(branch_info)
    end

    # Clones a branch
    # Parameters: name (String)
    def clone_branch(name, description=nil, message=nil)
      # Create the new branch
      description = "Clone of branch #{name}" if description.nil?
      new_branch(description)

      # Update changelog
      message = "Clone of branch #{name}" if message.nil?
      timestamp = Time.now.to_i
      branch_info = YAML.load_file(branch_info_path())
      #Rails.logger.debug branch_info.inspect
      branch_info[@name]['changelog'][timestamp] = create_changelog_entry(message)

      save_branch_info(branch_info)

      # Copy files
      FileUtils.cp_r("#{branch_path(name)}/objects/#{latest_commit(name)}", 
                     "#{branch_path()}/objects/#{timestamp}")
    end

    def change_branch_commit(timestamp = latest_commit())
      timestamp = latest_commit() if timestamp.blank?
      branch_info = YAML.load_file(branch_info_path())
      changelog_entry = branch_info[@name]['changelog'][timestamp]
      @commit = timestamp unless changelog_entry.nil?
    end

    def runs
      return load_branch_info()[@name]['runs'].to_i
    end

    def next_run(save=false)
      eid = runs().to_i + 1
      if save
        info = load_branch_info
        info[@name]['runs'] = eid
        save_branch_info(info)
      end
      return eid
    end    

    # Store the results of a given run
    # Note: this method will NOT remove any file passed..
    # Parameters: run_id (Integer), files (Array of strings (file paths))
    def save_run(run_id, files)
      run_path = "#{branch_path()}/runs/#{run_id}/"
      Dir.mkdir(run_path)

      files.each {|f|
        File.copy(f, run_path)
      }
    end
    
    # Returns the ID (timestamp of type Integer) of the latest commit
    # Parameters: name (String)
    def latest_commit(name=nil)
      name =  @name if name.nil?
      branch_info = YAML.load_file(branch_info_path(name))
      return branch_info[name]['changelog'].max()[0]
    end

    def commits(author=@user)
      commits = Hash.new()
      load_branch_info()[@name]['changelog'].each do |tm, c|
        commits[tm] = c if (c['author'] == author.to_s) or (author == :all)
      end
      return commits
    end

    def resource_map(timestamp=latest_commit())
      timestamp = latest_commit() if timestamp.blank?
      rs = YAML.load_file("#{branch_path()}/objects/#{timestamp}/resource_map.yml")
      return rs
    end
    
    def ed(timestamp=latest_commit())
      timestamp = latest_commit() if timestamp.blank?
      e = File.open("#{branch_path()}/objects/#{timestamp}/code.rb")
      return e.read()
    end

    # Checks if the resource map has changed
    # Parameters: resource_map (YAML)
    # Returns a boolean
    def resource_map_changed?(resource_map)
      rs = YAML.load_file("#{branch_path()}/objects/#{latest_commit()}/resource_map.yml")
      return !(rs == resource_map)
    end

    # Checks if the experiment definition has changed
    # Parameters: ed (String)
    # Returns a boolean
    def ed_changed?(ed)
      e = File.open("#{branch_path()}/objects/#{latest_commit()}/code.rb")
      return !(e == ed)
    end
  end
end

