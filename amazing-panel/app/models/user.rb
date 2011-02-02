class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :lockable and :timeoutable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable
  validates :username, :uniqueness => true
  
# Setup accessible (or protected) attributes for your model
  attr_accessible :email, :username, :intention, :password, :password_confirmation, :remember_me, 
                  :activated, :name, :leader, :institution
  scope :ge, lambda { |column, value| { :conditions => [column+" >= " + value] } }
  scope :le, lambda { |column, value| { :conditions => [column+" <= " + value] } }
  scope :l, lambda { |column, value| { :conditions => [column+" < " + value] } }
  scope :g, lambda { |column, value| { :conditions => [column+" > " + value] } }
  scope :eq, lambda { |column, value| { :conditions => [column+" = " + value] } }
  scope :in, lambda { |column, value| { :conditions => [column+" in " + value] } }
  scope :between, lambda { |column, _start, _end| { :conditions => [column+" BETWEEN "+start+" AND "+_end] } }
  scope :like, lambda { |column, value| { :conditions => [column+" = ?", value] } }
end
