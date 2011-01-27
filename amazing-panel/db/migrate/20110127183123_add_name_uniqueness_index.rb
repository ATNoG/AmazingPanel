class AddNameUniquenessIndex < ActiveRecord::Migration
  def self.up
      add_index :projects, :name, :unique => true
  end

  def self.down
      remove_index :projects, :name
  end
end
