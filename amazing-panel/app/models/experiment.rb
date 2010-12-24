class ResourcesMap < ActiveRecord::Base
  attr_accessible :progress, :node, :experiment, :sys_image, :testbed, :sys_image_id, :node_id
  belongs_to :node
  belongs_to :experiment
  belongs_to :sys_image
  belongs_to :testbed
end

class Experiment < ActiveRecord::Base 
  attr_accessible :description, :status, :created_at, :updated_at, :resources_map, :user
  belongs_to :ed
  belongs_to :phase
  belongs_to :user
  belongs_to :project
  has_many :resources_map
  has_many :nodes, :through => :resources_map
  has_many :sys_images, :through => :resources_map
  has_many :testbeds, :through => :resources_map
  scope :finished, where("status = 2 or status = 3") 
  scope :prepared, where("status = 0 ")
  scope :started, where("status = 1")
  scope :running, where("status = 0 or status = -1 or status = 1")

  def finished?
    return true if (status == 2 or status == 3)
  end

  def started?
    return true if (status == 1)
  end

  def prepared?
    return true if (status == 0 )
  end

  def preparing?
    return true if (status == -1)
  end
end
