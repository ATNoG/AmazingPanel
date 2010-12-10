class CreatePhases < ActiveRecord::Migration
  def self.up
    create_table :phases do |t|
      t.integer :number
      t.string :label
      t.string :description
    end
  end

  def self.down
    drop_table :phases
  end
end
