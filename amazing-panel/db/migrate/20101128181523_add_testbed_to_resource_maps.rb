class AddTestbedToResourceMaps < ActiveRecord::Migration
  def self.up
    add_column :resources_maps, :testbed_id, :integer
  end

  def self.down
    remove_column :resources_maps, :testbed_id
  end
end
