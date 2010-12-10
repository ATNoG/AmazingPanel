module OMF
  module Experiments
    module Controller
      class Proxy
        attr_accessor :id, :experiment
        
        def initialize(args)
          if args.class == Fixnum
            args = {:id => args }
          end
          unless args.nil? or args.length == 0
              @id = args[:id]
            @experiment = args[:id].nil? ? args[:experiment] : Experiment.find(@id)
          end
        end
  
        def prepare
           testbeds  = @experiment.resources_map.group(:testbed_id)
           testbeds.each do |t|
             images = @experiment.resources_map.group(:sys_image_id) 
             images.each do |img|
               op_testbed(t.testbed_id) {
                 ActiveRecord::Base.verify_active_connections!
                 load_resource_map(img, @experiment.nodes)
               }
             end
          end
        end
  
        def start
          op_testbed(1) {
            sleep 10
            puts "Starting..."
          }
        end
  
        def stop
          op_testbed(1) {
          }
        end

        protected
        def load_resource_map(img, nodes)
          comma_nodes = nodes.join(",");
          #popen("omf -i #{img.id}.ndz -t #{comma_nodes}");
        end
  
        def lock_testbed(t_id)
          lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
          ret = false
          data = { :experiment => @id, :pid => Process.pid }
          unless (ret = File.exists?(lock))
            open(lock, "w") { |f|
              f.write(ActiveSupport::JSON.encode(data))          
            }
          end
          return ret;
        end
  
        def unlock_testbed(t_id)
          lock = OMF::GridServices::testbed_rel_file_str(t_id, "lock")
          ret = false
          f = IO::read(lock)
          unless f.nil?
            ret = File.unlink(lock)
          end
          return ret
        end
  
        def op_testbed(t_id, &block)
          child = fork {
            lock_testbed(t_id)
            yield
            unlock_testbed(t_id)
          }        
          ret = Process.detach(child)
          return ret
        end
      end
    end
  end
end
