class ResourcesMap < ActiveRecord::Base
  attr_accessible :progress, :node, :experiment, :sys_image, :testbed, :sys_image_id, :node_id
  belongs_to :node
  belongs_to :experiment
  belongs_to :sys_image
  belongs_to :testbed
end

class Experiment < ActiveRecord::Base 
  attr_accessible :description, :status, :created_at, :updated_at, :resources_map
  belongs_to :ed
  belongs_to :phase
  belongs_to :user
  belongs_to :project
  has_many :resources_map
  has_many :nodes, :through => :resources_map
  has_many :sys_images, :through => :resources_map
  has_many :testbeds, :through => :resources_map
end
