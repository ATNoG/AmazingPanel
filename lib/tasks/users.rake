namespace :users do
  desc 'Simple user and group management task.'
  
  namespace :add do
    task :user => :environment do
      if ENV['user'].nil? or ENV['password'].nil?
         puts "Need user and password!"
         return
       end

       # group = amazingusers (1039)
       # no shell access
       cmd = `echo -e "#{ENV['password']}\n#{ENV['password']}" | sudo adduser #{ENV['user']} \
               --shell /bin/false \
               --gid 1039`
    end

    task :group => :environment do
      if ENV['group'].nil?
        puts "Need group name!"
        return
      end

      cmd = `sudo addgroup #{ENV['group']}`
    end

    task :usergroup do
      cmd = `useradd #{ENV['user']} -G #{ENV['group']}`
    end
  end

  namespace :delete do
    task :user => :environment do
      if ENV['user'].nil?
        puts "Need username!"
        return
      end

      cmd = `sudo deluser #{ENV['user']}`
    end

    task :group => :environment do
      if ENV['group'].nil?
        puts "Need group name!"
        return
      end

      cmd = `sudo delgroup #{ENV['group']}`
    end
  end
end

