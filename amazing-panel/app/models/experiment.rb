require 'omf.rb'
require 'omf/experiments.rb'

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
    unless record.nodes.blank?
      begin
        unless record.errors.has_key?(:nodes)    
          nodes = record.nodes.collect { |x| x.id }
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
end

class Experiment < ActiveRecord::Base 
  include OMF::Experiments::Controller
  include Delayed::Backend::ActiveRecord
  
  attr_accessible :description, :status, :created_at, :updated_at, :resources_map, :user, :runs, :failures

  attr_accessor :job_phase, :job_id
  
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

  scope :finished, where("status = 4 or status = 5") 
  scope :prepared, where("status = 2 or status = 5")
  scope :started, where("status = 3")
  scope :running, where("status = 1 or status = 3")
  scope :active, where("status >= 0 and status != 4")

  private
  
  # Fetch all jobs from queue
  def self.get_jobs(&block)
    ret = Array.new()
    jobs = Job.all.each do |job|
      object = YAML.load(job.handler)
      if block_given?
        block.call(job, object)
      else
        ret.push(job)
      end
    end
  end
  

  # From YAML File in the job convert to Experiment
  def self.from_job(job, object, user)
    exp = find(object.id.to_i)
    exp.job_phase = object.phase
    unless user.nil?
      exp.job_id = job.id if exp.project.users.where(:id => user.id).exists?
    end
    return exp
  end

  public
  # All experiment jobs from the queue
  def self.jobs(user, &block)    
    exp_jobs = Array.new()
    get_jobs do |job, object|
      if object.type == 'experiment'
        if block_given?
          block.call(job, object)
        else
          exp_jobs.push(from_job(job,object,user))
        end
      end
    end
    return exp_jobs
  end
 
  # All experiment failed jobs from the queue
  def self.failed_jobs(user)
    exp_jobs = Array.new()
    jobs(user) do |job, object|
      unless job.failed_at.nil?
        exp_jobs.push(from_job(job,object,user))
      end
    end
    return exp_jobs
  end

  #
  # Fetch SQLite3 Database
  def sq3(run=nil, dump=false)
    id = self.id
    ec = OMF::Experiments::Controller::Proxy.new(id)
    exp_id = run.nil? ? "#{id}_#{ec.runs.first}.sq3" : "#{id}_#{run}.sq3"
    results = "#{APP_CONFIG['exp_results']}#{id}/#{run}/#{exp_id}"       
    unless dump == false
      return IO.popen("sqlite3 #{results} .dump").read
    end
    return results
  end

  # Fetch content of SQLite3 Database
  def results(run)
    Rails.logger.debug self.id
    ec = OMF::Experiments::Controller::Proxy.new(self.id)
    r = ec.runs
    run = r.max() if r.length > 0 and run.nil?
    
    _tmp = OMF::Experiments.results(self, {:run => run})
    db = _tmp[:results]
    metrics = _tmp[:metrics]
    results = Hash.new()
    seq_num = Array.new()
    length = 0;
    metrics.each do |m|
      model = db.select_model_by_metric(m[:app], m[:metrics])
      table = model.table_name()
      columns = model.column_names()
      oml_seq = model.find(:all, :from => "#{table}", :select => "oml_seq")      
      dataset = model.find(:all, :from => "#{table}")      
      length = dataset.length
      results[table] = { 
        :columns => columns, 
        :set => dataset, 
        :length => length
      }
    end
    seq_num = (1..length).to_a
    return { :seq_num => seq_num, :results => results, :runs_list => r }
  end
  
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
