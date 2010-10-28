class CreateSysImages < ActiveRecord::Migration
  def self.up
    create_table :sys_images do |t|
      t.references :user
      t.references :sys_image
      t.integer :size
      t.string :kernel_version_os
      t.string :name
      t.string :description      
      t.boolean :baseline
      
      t.timestamps
    end
  end

  def self.down
    drop_table :sys_images
  end
end
