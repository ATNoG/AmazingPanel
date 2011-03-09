class ResourceMapValidator < ActiveModel::Validator
  def validate(record)
    allowed = record.experiment.ed.allowed()
    missing = Array.new(allowed).delete_if { |x| !allowed.index(x).nil?  } 
    begin
      record.errors[:node] << I18n.t("errors.experiment.resources_map.dont_exist") unless Node.find(record.node_id)
      record.errors[:sys_image] << I18n.t("errors.experiment.resources_map.dont_exist") unless SysImage.find(record.sys_image_id)
      record.errors[:testbed] << I18n.t("errors.experiment.resources_map.dont_exist") unless Testbed.find(record.testbed_id)
      if allowed.index(record.node_id).nil?
        record.experiment.errors[:nodes] = t("errors.experiment.nodes.allowed", :nodes => allowed.sort.join(","))
      end
    rescue
      record.experiment.errors[:resources_map] = I18n.t("errors.experiment.resources_map.invalid")
    end    
  end
end

class ResourcesMap < ActiveRecord::Base
  attr_accessible :progress, :node, :experiment, :sys_image, :testbed_id, :sys_image_id, :node_id
  belongs_to :node
  belongs_to :experiment
  belongs_to :sys_image
  belongs_to :testbed

  validates :node_id, :presence => true
  validates :sys_image_id, :presence => true
  validates :testbed_id, :presence => true
  validates_with ResourceMapValidator
end

class ExperimentEdValidator < ActiveModel::Validator
  def validate(record)
    record.errors.add(:ed, I18n.t("errors.experiment.ed.empty")) unless record.ed.code.size > 0
    record.errors.add(:nodes, I18n.t("errors.experiment.nodes.invalid")) if record.ed.allowed.blank?
    begin
      unless record.errors.has_key?(:nodes)    
        nodes = record.send(:nodes)
        allowed = record.ed.allowed
        missing = Array.new(allowed).delete_if { |x| 
          !nodes.index(x).nil?
        } 
        if missing.size > 0
          record.errors.add(:nodes, I18n.t("errors.experiment.nodes.missing", :nodes => missing.sort.join(",")))
        end
      end
    rescue
      record.errors.add(:nodes, I18n.t("errors.experiment.nodes.invalid"))
    end
  end
end

class Experiment < ActiveRecord::Base 
  attr_accessible :description, :status, :created_at, :updated_at, :resources_map, :user, :runs, :failures
  attr_accessor :nodes
  belongs_to :ed
  belongs_to :phase
  belongs_to :user
  belongs_to :project
  
  delegate :code, :to => :ed, :prefix => true
  
  has_many :resources_map, :dependent => :destroy
  has_many :nodes, :through => :resources_map
  has_many :sys_images, :through => :resources_map
  has_many :testbeds, :through => :resources_map

  validates_with ExperimentEdValidator, :fields => [ :nodes ]

  def nodes=(_nodes)
    _nodes.delete("testbed") unless _nodes.blank?
    unless _nodes.blank?
      ns = Array.new()
      _nodes.each do |k,v|
        node = Node.find(k)
        sysimage = SysImage.find(v["sys_image"])              
        ns.push(node.id.to_i)
      end
      logger.debug(ns)
      write_attribute(:nodes, ns)
    end
  end

  def nodes
    read_attribute(:nodes)
  end

  scope :finished, where("status = 4 or status = 5") 
  scope :prepared, where("status = 2 or status = 5")
  scope :started, where("status = 3")
  scope :running, where("status = 1 or status = 3")
  scope :active, where("status >= 0 and status != 4")
  
  # Helper methods for the experiment status
  def finished?
    if (status == 4 or status == 5) then return true end 
    return false
  end

  def started?
    if (status == 3) then return true end
    return false
  end

  def prepared_only?
    if (status == 2) then return true end
    return false
  end

  def prepared?
    if (status >= 2 and status != 4) then return true end
    return false
  end

  def preparing?
    if (status == 1) then return true end 
    return false
  end

  def not_init?
    if (status == 0) then return true end
    return false
  end 
  
  def init?    
    if (status == 0 or status == 4) then return false end
    return true
  end

  def failed?
    if (status < 0) then return true end
    return false    
  end

  def preparation_failed?
    if (status==-1) then return true end
    return false
  end

  def experiment_failed?
    if (status==-2) then return true end
    return false
  end
end
