class Location < ActiveRecord::Base  
  attr_accessible :id, :name, :x, :y, :z, :latitude, :longitude, :elevation
  belongs_to :testbed
end
