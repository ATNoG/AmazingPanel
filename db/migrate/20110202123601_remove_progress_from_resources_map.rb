class RemoveProgressFromResourcesMap < ActiveRecord::Migration
  def self.up
    remove_column :resources_maps, :progress
  end

  def self.down
    add_column :resources_maps, :progress, :integer
  end
end
