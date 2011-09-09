class ChangeSysImageDescriptionType < ActiveRecord::Migration
  def self.up
    change_column :sys_images, :description, :text
  end

  def self.down
    change_column :sys_images, :description, :string
  end
end
