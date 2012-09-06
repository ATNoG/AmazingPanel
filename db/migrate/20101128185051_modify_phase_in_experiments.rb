class ModifyPhaseInExperiments < ActiveRecord::Migration
  def self.up
    remove_column :experiments, :phase
    add_column :experiments, :phase_id, :integer
  end

  def self.down
    remove_column :experiments, :phase_id
    add_column :experiments, :phase, :integer
  end
end
