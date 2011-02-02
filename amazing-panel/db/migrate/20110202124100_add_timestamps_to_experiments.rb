class AddTimestampsToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :created_at, :datetime
    add_column :experiments, :updated_at, :datetime
  end

  def self.down
    remove_column :experiments, :updated_at
    remove_column :experiments, :created_at
  end
end
