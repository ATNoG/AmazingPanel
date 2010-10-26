class CreateSysImages < ActiveRecord::Migration
  def self.up
    create_table :sys_images do |t|
      t.string :name 
      t.string :description
      t.references :base_sys_image

      t.timestamps
    end
  end

  def self.down
    drop_table :sys_images
  end
end
