class Project < ActiveRecord::Base
  validates_presence_of :name, :description
  attr_accessible :name, :description, :user_ids, :leader
  
  has_and_belongs_to_many :users  
end