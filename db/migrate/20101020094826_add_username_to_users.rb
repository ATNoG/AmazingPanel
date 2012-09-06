class AddUsernameToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :admin, :boolean, :default => false    
    add_column :users, :activated, :boolean, :default => false
    add_column :users, :username, :string
    add_column :users, :intention, :string
  end

  def self.down
    remove_column :users, :admin
    remove_column :users, :username
    remove_column :users, :activated
    remove_column :users, :intention
  end
end
