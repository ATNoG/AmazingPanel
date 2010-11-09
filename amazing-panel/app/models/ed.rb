class Ed < ActiveRecord::Base
  scope :ge, lambda { |column, value| { :conditions => [column+" >= " + value] } }
  scope :le, lambda { |column, value| { :conditions => [column+" <= " + value] } }
  scope :l, lambda { |column, value| { :conditions => [column+" < " + value] } }
  scope :g, lambda { |column, value| { :conditions => [column+" > " + value] } }
  scope :eq, lambda { |column, value| { :conditions => [column+" = " + value] } }
  scope :in, lambda { |column, value| { :conditions => [column+" in " + value] } }
  scope :between, lambda { |column, _start, _end| { :conditions => [column+" BETWEEN "+start+" AND "+_end] } }
  scope :like, lambda { |column, value| { :conditions => [column+" = ?", value] } }
  
  attr_accessible :id, :user_id, :name, :description, :created_at, :updated_at
end
