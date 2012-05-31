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
        def initialize(experiment, args, app={})
          @config = {
            :adapter => "sqlite3",
            :database => experiment.repository.current.branch_results_path(args[:run]) 
          }
          @tables = { }
          if (app == {})
            load_models(self.class)
          else
            create_models(app)
          end
        end

        def select_model_by_metric(app, metrics, &block)
          ts = Array.new()
          Data.connection.tables.each do |t|
            #if (app.select {|e| t.include?(e) }).length > 0
               if (metrics.select {|mt| t.include?(mt[:name]) }).length > 0
                    ts.push(t)
               end
            #end
          end
          ts.each do |table|
            Data.reset_column_information()
            Data.set_table_name(table)
            Rails.logger.info("Data for #{table}")
            block.call(Data)
          end
        end

        def select_model(table)
          Data.set_table_name(table)
          return Data;
        end

        def get_metrics_by_results()
          apps = {}
          Data.connection.tables.select{|e| not_metadata(e) }.each do |t|
            toks = t.split("_")
            app_name = toks[0]
            toks.delete_at(0)
            apps[app_name] = [] if apps[app_name].nil?
            measure = toks.join("_")
            apps[app_name].push(measure)
          end

          ret = []
          apps.each do |app, metrics_a|
            ret.push({
              :raw => true,
              :app  => app,
              :metrics => metrics_a.collect{ |e| { :name => e } }
            })
          end
          return ret
        end

        protected
          def not_metadata(table_name)
            return !(["_senders","_experiment_metadata"].include?(table_name))
          end

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

