class AddRunsToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :runs, :integer
  end

  def self.down
    remove_column :experiments, :runs
  end
end
