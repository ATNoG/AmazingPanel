require 'omf'

namespace :omf do
  desc 'OMF task capable of restarting the aggregate manager and nodes'
  
  namespace :restart do
    task :all => [:aggregate, :nodes] do
    end

    task :aggregate do
      puts "Restarting aggregate manager..."
      cmd = `sudo service omf-aggmgr-5.3 restart`
    end

    task :nodes do
      include OMF::GridServices
      # NOTE: jimbo only manages nodes up to node 5.
      ts = OMF::GridServices::TestbedService.new(1)
      for i in 0..4
        puts "Shutting down node #{i}..."
        ts.power_off(i)
        puts "Starting down node #{i}..."
        ts.power_on(i)
      end
    end
  end

end

