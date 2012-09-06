class CreateResourcesMaps < ActiveRecord::Migration
  def self.up
    create_table :resources_maps do |t|
      t.references :experiment
      t.references :node
      t.references :sys_image
      t.timestamps
    end
  end

  def self.down
    drop_table :resources_maps
  end
end

