class AddProjectToExperiments < ActiveRecord::Migration
  def self.up
    change_table :experiments do |t|
      t.references :project
    end
  end

  def self.down
    remove_column :experiments, :project_id
  end
end
