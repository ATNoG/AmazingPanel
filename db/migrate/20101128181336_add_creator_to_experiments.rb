class AddCreatorToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :user_id, :string
  end

  def self.down
    remove_column :experiments, :user_id
  end
end
