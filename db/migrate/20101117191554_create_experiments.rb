class CreateExperiments < ActiveRecord::Migration
  def self.up
    create_table :experiments do |t|
      t.references :ed
      t.references :resources_map
      t.datetime :start_at
      t.integer :duration
      t.integer :phase
      t.integer :status
    end
  end

  def self.down
    drop_table :experiments
  end
end
