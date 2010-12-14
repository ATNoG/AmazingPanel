class Project < ActiveRecord::Base
  validates_presence_of :name, :description
  validate :name, :uniqueness => { :case_sensitive => false }

  has_and_belongs_to_many :users
  
  attr_accessible :name, :description, :user_ids, :leader
end
