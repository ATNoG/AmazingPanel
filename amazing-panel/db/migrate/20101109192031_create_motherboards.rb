class CreateMotherboards < ActiveRecord::Migration
  def self.up
    create_table :motherboards do |t|

      t.timestamps
    end
  end

  def self.down
    drop_table :motherboards
  end
end
