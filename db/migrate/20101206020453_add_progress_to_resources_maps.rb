class AddProgressToResourcesMaps < ActiveRecord::Migration
  def self.up
    add_column :resources_maps, :progress, :integer
  end

  def self.down
    remove_column :resources_maps, :progress
  end
end
