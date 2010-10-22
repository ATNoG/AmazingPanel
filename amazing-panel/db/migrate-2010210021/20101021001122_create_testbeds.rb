class CreateTestbeds < ActiveRecord::Migration
  def self.up
    create_table :testbeds do |t|
      t.string :name
      t.string :description

      t.timestamps
    end
  end

  def self.down
    drop_table :testbeds
  end
end