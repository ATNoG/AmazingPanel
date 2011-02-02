class RemoveStartAtFromExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments, :start_at
  end

  def self.down
    add_column :experiments, :start_at, :datetime
  end
end
