class CreateTestbedsUsers < ActiveRecord::Migration
  def self.up      
    create_table :testbeds_users, :id => false do |t|
      t.integer :testbed_id
      t.integer :user_id
      t.boolean :leader, :default => false
    end
  end

  def self.down
    drop_table :testbeds_users
  end
end