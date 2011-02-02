class Project < ActiveRecord::Base
  validates_presence_of  :description
  validates :name, :presence => true, :uniqueness => true 

  has_and_belongs_to_many :users
  
  attr_accessible :name, :description, :user_ids, :leader, :private
end
