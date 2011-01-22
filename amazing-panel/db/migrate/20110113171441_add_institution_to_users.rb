class AddInstitutionToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :institution, :string
  end

  def self.down
    remove_column :users, :institution
  end
end
