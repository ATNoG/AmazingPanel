class AddFailuresToExperiments < ActiveRecord::Migration
  def self.up
    add_column :experiments, :failures, :integer
  end

  def self.down
    remove_column :experiments, :failures
  end
end
