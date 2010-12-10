module OMF
  module Experiments
      class GenericResults
        class OMLGenerated < ActiveRecord::Base
          abstract_class = true
        end
        class DataGenerated < ActiveRecord::Base
          abstract_class = true
        end
        class Sender < OMLGenerated
          set_table_name('_senders')
        end
        class ExperimentMetadata < OMLGenerated
          set_table_name('_experiment_metadata')
        end
        class Data < DataGenerated
          abstract_class = true
        end
        
        attr_accessor :tables, :config
        def initialize(experiment, app={})
          @config = { 
            :adapter => "sqlite3", 
            :database => "#{Rails.root}/inventory/experiments/#{experiment.id}.sq3" 
          }
          
          @tables = {}
          if (app == {})
            load_models(self.class)
          else
            create_models(app)
          end
        end
        
        def select_model_by_metric(app, metrics)
          ts = Array.new()
          Data.connection.tables.each do |t|
            if (app.select {|e| t.include?(e) }).length > 0         
            #pp "for <#{t}> --> #{has_app}"
              if (metrics.select {|mt| t.include?(mt[:name]) }).length > 0
                ts.push(t)
              end
            end
          end
          if ts.length == 1
            Data.set_table_name(ts[0])
            return Data
          end
          return nil
        end
  
        def select_model(table)
          Data.set_table_name(table)
          return Data;
        end
        
        protected
        def load_models(klass)
          klass.constants.each do |rt|
            rt_class = klass.const_get(rt)
            rt_superclass = rt_class.superclass
              unless rt_superclass != DataGenerated
              #puts "Class: #{rt_class}"
              rt_class.establish_connection(@config)
              @tables[rt_class.to_s] = rt_class
            end
          end
        end   
      end
  end
end
