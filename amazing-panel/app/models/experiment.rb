class ResourcesMap < ActiveRecord::Base
  attr_accessible :progress, :node, :experiment, :sys_image, :testbed, :sys_image_id, :node_id
  belongs_to :node
  belongs_to :experiment
  belongs_to :sys_image
  belongs_to :testbed
end

class Experiment < ActiveRecord::Base 
  attr_accessible :description, :status, :created_at, :updated_at, :resources_map, :user, :runs, :failures
  belongs_to :ed
  belongs_to :phase
  belongs_to :user
  belongs_to :project
  has_many :resources_map
  has_many :nodes, :through => :resources_map
  has_many :sys_images, :through => :resources_map
  has_many :testbeds, :through => :resources_map
  scope :finished, where("status = 4 or status = 5") 
  scope :prepared, where("status = 2 or status = 5")
  scope :started, where("status = 3")
  scope :running, where("status = 1 or status = 3")
  scope :active, where("status >= 0 and status != 4")

  def finished?
    if (status == 4 or status == 5)
      return true
    end 
    return false
  end

  def started?
    if (status == 3)
      return true
    end
    return false
  end

  def prepared_only?
    if (status == 2)
      return true
    end
    return false
  end

  def prepared?
    if (status >= 2 and status != 4)
      return true
    end
    return false
  end

  def preparing?
    if (status == 1)
      return true
    end
    return false
  end

  def not_init?
    if (status == 0)
      return true
    end
    return false
  end 
  def init?
    if (status == 0 or status == 4)
      return false
    end
    return true
  end

  def failed?
    return true if (status < 0)
    return false    
  end

  def preparation_failed?
    return true if (status==-1)
    return false
  end

  def experiment_failed?
    return true if (status==-2)
    return false
  end
end
