namespace :evc do
  desc 'EVC tasks to manage experiment repositories in inventory'

  task :migrate => :environment do |t, args|
    require 'evc'
    id = args[:id]
    user_arg = args[:user]

    user_by_id = User.find_by_id(user_arg)
    user_by_username = User.find_by_username(user_arg)

    user = user_by_id unless user_by_id.blank?
    user = user_by_username unless user_by_username.blank?
    experiment = Experiment.find_by_id(id)

    if experiment.blank?
      puts "Experiment not found."
      return false
    end

    user = experiment.user unless (user_by_username.blank? and user_by_id.blank?)

    if user.blank?
      puts "User not found."
      return false
    end

    puts "Initializing repository for experiment ##{experiment.id}, user=##{user.id}"
    master = EVC::Repository.new(id, user)
    map = Hash.new()
    experiment.resources_map.all.collect do |rm| 
      map[rm.node_id] = rm.sys_image_id
    end

    puts "Creating master branch"
    ret = master.init(map)
    if ret = false
      puts "error: Failed to create!"
      return false
    end

    # Move runs to master
    puts "Moving existing runs to master branch"
    blacklist = [".", "..", "branches"]
    last = -1; success = 0
    repository_path = master.repository_path
    Dir.foreach("#{repository_path}") { |run|
      last = run.to_i if run.to_i > last
      unless blacklist.include?(run)
        success += 1
        FileUtils.cp_r("#{repository_path}/#{run}", "#{repository_path}/branches/master/runs/#{run}") 
        puts "\tfound run #{run}"
      end
    }    

    puts "Refreshing branch info"
    runs = last + 1
    failures = runs - success
    # Refresh runs in branch info
    master_branch_info = YAML.load_file("#{master.current.branch_info_path()}")
    master_branch_info["master"]["runs"] = runs
    master_branch_info["master"]["failures"] = failures
    master.current.save_branch_info(master_branch_info)
  end

  namespace :migrate do
    task :all => :environment do 
      blacklist = [".", ".."]
      experiments_inventory_path = "#{APP_CONFIG['inventory']}/experiments"
      Dir.foreach(experiments_inventory_path) { |exp|
        experiment_path = "#{experiments_inventory_path}/#{exp}"
        unless blacklist.include?(exp)
            if File.directory?(experiment_path)
              experiment = Experiment.find_by_id(exp)
              next if experiment.blank?
              ENV['id'] = experiment.id.to_s
              ENV['user'] = experiment.user.id.to_s
              Rake::Task["evc:migrate"].reenable
              Rake::Task["evc:migrate"].invoke()
            end
        end
      }
    end
  end
end
