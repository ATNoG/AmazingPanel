require 'omf.rb'
require 'omf/experiments.rb'

class ResourceMapValidator < ActiveModel::Validator
  def validate(record)
    allowed = record.experiment.ed.allowed()
    missing = Array.new(allowed).delete_if { |x| !allowed.index(x).nil?  } 
    begin
      unless Node.find(record.node_id)
        record.errors[:node] << I18n.t("errors.experiment.resources_map.dont_exist") 
      end
      unless SysImage.find(record.sys_image_id) 
        record.errors[:sys_image] << I18n.t("errors.experiment.resources_map.dont_exist")     
      end
      unless Testbed.find(record.testbed_id)
        record.errors[:testbed] << I18n.t("errors.experiment.resources_map.dont_exist")
      end
      if allowed.index(record.node_id).nil?
        record.experiment.errors[:nodes] = t("errors.experiment.nodes.allowed", 
                                             :nodes => allowed.sort.join(","))
      end
    rescue
      record.experiment.errors[:resources_map] = I18n.t("errors.experiment.resources_map.invalid")
    end    
  end
end

class ResourcesMap < ActiveRecord::Base
  self.abstract_class = true
  instance_variable_set :@columns, []

  attr_accessible :experiment, :testbed_id, :sys_image_id, :node_id
  attr_accessor :testbed_id, :sys_image_id, :node_id
  
  belongs_to :node
  belongs_to :experiment
  belongs_to :sys_image
  belongs_to :testbed

  validates :node_id, :presence => true
  validates :sys_image_id, :presence => true
  validates :testbed_id, :presence => true
  validates_with ResourceMapValidator

  def node
    Node.find(self.node_id)
  end

  def testbed
    Testbed.find(self.testbed_id)
  end

  def sys_image
    SysImage.find(self.sys_image_id)
  end
end

class ExperimentEdValidator < ActiveModel::Validator
  def validate(record)
    unless record.ed.code.size > 0
      record.errors.add(:ed, I18n.t("errors.experiment.ed.empty"))
    end

    if record.ed.allowed.blank?
      record.errors.add(:nodes, I18n.t("errors.experiment.nodes.invalid"))
    end
    
    unless record.nodes.blank?
      begin
        unless record.errors.has_key?(:nodes)    
          nodes = record.nodes.collect { |x| x.id }
          allowed = record.ed.allowed
          missing = Array.new(allowed).delete_if { |x| 
            !nodes.index(x).nil?
          } 
          if missing.size > 0
            record.errors.add(:nodes, 
                I18n.t("errors.experiment.nodes.missing", 
                       :nodes => missing.sort.join(",")))
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
  
  attr_accessible :description, :status, :created_at, :updated_at, :user, 
    :project, :ed

  attr_accessor :job_phase, :job_id, :proxy, :repository, :code, :revisions,
    :resources_map, :nodes, :sys_images, :testbeds, :info
  
  belongs_to :ed
  belongs_to :phase
  belongs_to :user
  belongs_to :project  

  #validates_with ExperimentEdValidator, :fields => [ :nodes ]
  after_initialize :load_all
  after_create :create_repository
 
  """
  Custom Callbacks 
  """
  def after_clone_branch()
    set_resources_map()
  end

  def after_commit_branch()
    set_resources_map()
  end

  def after_change_branch()
    set_ed_code()
    set_resources_map()
    set_branch_info()
    @attributes.delete('revision')
  end

  scope :finished, where("status = 4 or status = 5") 
  scope :prepared, where("status = 2 or status = 5")
  scope :started, where("status = 3")
  scope :running, where("status = 1 or status = 3")
  scope :active, where("status >= 0 and status != 4")


  private    
  """
    After initialization it loads a Proxy to the OMF Experiment Controller
  and initialize the data from EVC
  """
  def load_all
    unless self.id.blank?
      set_user_repository(self.user) unless self.user.nil?
      load_proxy
    end
  end
  
  """
  Check if repository is initialized
  """
  def check_repository
    if self.repository.blank? then return false end
    return true
  end

  """
  Fetch all jobs from queue
  """
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
  

  """
  From YAML File in the job convert to Experiment
  """
  def self.from_job(job, object, user)
    exp = find(object.id.to_i)
    exp.job_phase = object.phase
    unless user.nil?
      exp.job_id = job.id if exp.project.users.where(:id => user.id).exists?
    end
    return exp
  end

  public

  def load_proxy
    self.proxy = ProxyClass.new({:experiment => self})
  end

  """
    All experiment jobs from the queue
  """
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
 
  """ 
  All experiment failed jobs from the queue
  """
  def self.failed_jobs(user)
    exp_jobs = Array.new()
    jobs(user) do |job, object|
      unless job.failed_at.nil?
        exp_jobs.push(from_job(job,object,user))
      end
    end
    return exp_jobs
  end


  """
  Fetch SQLite3 Database
  """
  def sq3(run=nil, dump=false)
    id = self.id
    results = self.repository.current.branch_results_path(run)       
    unless dump == false
      IO.popen("sqlite3 #{results} .dump") { |f|
        return f.read
      }
    end
    return results
  end

  """
  Fetch content of SQLite3 Database
  """
  def results(run)
    r = self.repository.current.runs_with_results
    if r.length > 0 and run.nil?
      run = r.max()
    elsif r.length == 0
      return { :seq_num => [], :results => {}, :runs_list => []}
    end
    
    _tmp = OMF::Experiments.results(self, {:repository => self.repository.current, :run => run})
    db = _tmp[:results]
    metrics = _tmp[:metrics]
    results = Hash.new()
    seq_num = Array.new()
    length = 0;
    metrics.each do |m|
      db.select_model_by_metric(m[:app], m[:metrics]) do |model|
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
    end
    seq_num = (1..length).to_a
    return { :seq_num => seq_num, :results => results, :runs_list => r }
  end
  
  """
  Enqueue a experiment start job to the queue
  """
  def start
    ec = self.proxy
    njobs = Job.all.size
    ret = false
    if ec.check(:prepared)
      if njobs > 0
        ret = true
      end
      Delayed::Job.enqueue StartExperimentJob.new('start', self.id)      
    end
    return ret
  end
  
  """
  Enqueue a experiment run job to the queue
  """
  def run(n, user_id, revision)
    njobs = Job.all.size
    ret = false
    if njobs > 0
      ret = true
    end
    Delayed::Job.enqueue RunExperimentJob.new(self.id.to_i, user_id, n, revision, self.current)
    return ret
  end

  """
  Enqueue a experiment prepare job to the queue
  """
  def prepare
    njobs = Job.all.size
    ret = false
    if njobs > 0
      ret = true
    end
    Delayed::Job.enqueue PrepareExperimentJob.new('prepare', self.id.to_i)
    return ret
  end

  """
  Enqueue a experiment stat job to the queue
  """
  def stat(with_log=false)
    tmp = {}
    tmp = self.proxy.status()    
    return tmp
  end
  
  def set_proxy_author(user)
    self.proxy.author = user.username
  end

  """
    Initializes the repository related to a user
  """
  def set_user_repository(user) 
    self.repository = EVC::Repository.new(self.id, user)
    if self.repository.exists?()
      set_ed_code()
      set_resources_map()    
      set_branch_info()    
    end
  end  
  
  """
    Initializes current experiment info
  """
  def set_branch_info
    self.info = self.repository.current.load_branch_info()[current()]
  end

  """
    Initializes the code related to the current branch
  """
  def set_ed_code()
    revision = @attributes.has_key?('revision') ? @attributes['revision'] : nil
    self.code = self.repository.current.ed(revision)
  end

  """
    Initializes the resources map related to the current branch
  """
  def set_resources_map(rms=nil)    
    revision = @attributes.has_key?('revision') ? @attributes['revision'] : nil
    repository.current.change_branch_commit(revision) unless repository.nil?
    self.resources_map.clear() unless self.resources_map.nil?
    valid = false
    if rms.nil?
      tmp = repository.current.resource_map(revision)['resources']
    elsif rms.has_key?('resources')
      tmp = rms['resources']
      @attributes['raw_rms'] = rms
      valid = true
    end

    tmp.each do |k,v|
      is_hash = (v.class == Hash)
      t = is_hash ? v['testbed'] : nil
      sy = is_hash ? v['sys_image'] : v
      add_resource_map(k,sy,t,valid)
    end

    self.nodes = self.resources_map.collect{ |rm| rm.node_id }
    self.sys_images = self.resources_map.collect{ |rm| rm.sys_image_id }
    self.testbeds = self.resources_map.collect{ |rm| rm.testbed_id }
  end

  def add_resource_map(node, sysimage, testbed, valid=false)
    self.resources_map = Array.new() if self.resources_map.blank?
    testbed = Testbed.first.id if testbed.blank?
    params = {
      :experiment => self, 
      :testbed_id => testbed, 
      :node_id => node, 
      :sys_image_id => sysimage
    }
    rm = ResourcesMap.new(params)
    is_valid = !valid
    is_valid = rm.valid? if valid
    self.resources_map.push(rm) if is_valid
    return is_valid
  end
  
  def has_repository?
    return self.repository.exists?
  end

  def create_repository()
    if self.valid?      
      self.repository = EVC::Repository.new(self.id, user)
      ret = self.repository.init(@attributes['raw_rms'])
      return ret
    end
  end

  def each_log_line(name, &block)
  	IO::readlines(name).each do |line|
  	 	re = /(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}) (DEBUG|INFO|ERROR) (.*)/
  		md = re.match(line)
  		if md
  			yield md[1], md[2], md[3]
  		end
  	end
  end

  def log(run=nil)
    runs = self.repository.current.runs_with_results
    run = runs.first if run.nil?
    path = self.repository.current.branch_run_path(run, "log")

    logl = []
    unless run.blank? 
      each_log_line(path) do |date, level, content|
      	logl.push({ :date => date, :level => level, :content => content })
      end
    end
    return logl
  end
    
  """
    Fetch the list of all branches from EVC
    Parameters: None.
  """
  def branches
    unless check_repository then return nil end
    return self.repository.branches.keys
  end

  """
    Clones the repository <name> from a parent branch (default: master)
    Parameters: None.
  """
  def clone(name, parent="master")
    unless check_repository then return false end
    ret = self.repository.clone_branch(name, parent)
    ret = self.repository.change_branch(name) if ret
    after_clone_branch()
    return ret
  end
  
  """
    Fetch current branch from repository
    Parameters: None.
  """
  def current
    unless check_repository then return nil end
    return self.repository.current.name
  end


  """
  Fetch runs from the current branch
  """
  def runs
    pp self.repository
    return self.repository.current.runs
  end
  
  """
  Generate and save runs in the current branch
  """
  def next_run(save=false)
    return self.repository.current.next_run(save)
  end

  def failures
  """
  Fetch failures from the current branch
  """
    return self.info['failures']
  end

  """
    Get revisions from author
  """
  def revisions(author=:all)
    unless check_repository then return nil end
    return self.repository.current.commits(author)
  end

  """
    Commit the changes on current working branch
  """
  def commit(branch, code, rm, message="Empty message")
    unless check_repository then return nil end
    ret = self.repository.branches[branch].commit_branch(message, code, rm)
    after_commit_branch()
    return ret
  end

  """
    Change the current working branch on experiment
  """
  def change(branch='master', revision=nil)
    unless check_repository then return nil end
    ret = self.repository.change_branch(branch)
    @attributes['revision'] = revision unless revision.nil?
    after_change_branch()
    return ret
  end

  """
    Check for experiment statuses: finished, started, prepared, failed, finished.
  """
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
