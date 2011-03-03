module EVC
  class Branch
    attr_accessor :name, :user

    def initialize(name, user)
      @name = name
      @user = user
    end

    def branch_path()
      return "#{APP_CONFIG['evc']}/branches/#{@name}"
    end

    def branch_info_path()
      return "#{branch_path()}/.info"
    end

    def create_changelog_entry(message)
      return {"author" => @user, "message" => message}
    end

    def save_file(branch_info)
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
      branch_info[@name] = {"author" => @user, "runs" => 0, "failures" => 0, "changelog" => {Time.now.to_i => create_changelog_entry("Initial commit") } }
      save_file(branch_info)

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
      File.open("#{branch_path()}/objects/#{timestamp}/resource_map.rb", 'w') {|f|
        f.write(resource_map.to_yaml)
      }

      # Update changelog
      branch_info = YAML::load(File.open(branch_info_path()))
      branch_info[@name]['changelog'][timestamp] = create_changelog_entry(message)
      save_file(branch_info)
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
  end
end

