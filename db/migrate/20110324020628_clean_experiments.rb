class CleanExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments, :duration
    remove_column :experiments, :phase_id
    remove_column :experiments, :runs
    remove_column :experiments, :failures
    remove_column :experiments, :resources_map_id
  end

  def self.down
    add_column :experiments, :duration, :integer
    add_column :experiments, :phase_id, :integer
    add_column :experiments, :runs, :integer
    add_column :experiments, :failures, :integer
    add_column :experiments, :resources_map_id, :integer
  end
end
