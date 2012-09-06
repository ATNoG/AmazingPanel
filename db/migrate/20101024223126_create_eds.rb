class CreateEds < ActiveRecord::Migration
  def self.up
    create_table :eds do |t|
      t.references :user
      t.string :name
      t.string :description
      t.timestamps
    end
  end

  def self.down
    drop_table :eds
  end
end
