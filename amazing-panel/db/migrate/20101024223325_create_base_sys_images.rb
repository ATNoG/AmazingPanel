class CreateBaseSysImages < ActiveRecord::Migration
  def self.up
    create_table :base_sys_images do |t|
      t.string :name
      t.timestamps
    end
  end

  def self.down
    drop_table :base_sys_images
  end
end
