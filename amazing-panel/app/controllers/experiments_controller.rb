require 'omf.rb'
require 'omf/experiments.rb'

class ExperimentsController < ApplicationController
  include OMF::GridServices
  include OMF::Experiments::Controller
  include Delayed::Backend::ActiveRecord

  include Library::SysImagesHelper
  include ProjectsHelper  


  #layout 'experiments'
  before_filter :authenticate
  append_before_filter :is_public, :only => [:show] 
  
  respond_to :html, :js

  def queue
    @prepared = Experiment.prepared
    @queue = get_experiment_jobs()
  end 
  
  def index
    @has_exp_in_cache = (session[:experiment].nil? ) ? false : true;
    case 
    when params.has_key?("active")
      @experiments = Experiment.running
    when params.has_key?("done")
      @experiments = Experiment.finished
    else
      @experiments = Experiment.all
    end
  end

  def show
    @experiment = Experiment.find(params[:id])
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
  	@status = @experiment.status
    @nodes = Hash.new()
    @experiment.resources_map.each do |rm|
      @nodes[rm.node_id] = rm.sys_image_id
    end
    
    unless params.has_key?("resources")    
      #@log = OMF::Experiments::Controller::Proxy.new(params[:id].to_i).log
      @log = ""
    end
    
    case 
    when params.has_key?("resources")
      @resources = @experiment.resources_map
      @testbed = @resources.first.testbed
      service = OMF::GridServices::TestbedService.new(@testbed.id);
      @nodes = service.mapping()
      @has_map = service.has_map()
      #@nodes = OMF::GridServices.testbed_status(@testbed.id)
    when @experiment.finished?
      run = params[:run]      
      @raw_results = ec.runs
      if ec.runs.length > 0
        ret = run.nil? ? fetch_results(@experiment) : fetch_results(@experiment, run) 
        @results = ret[:results]
        @seq_num = ret[:seq_num]
      end
    end
    respond_to do |format|
      format.sq3 {
        render_sqlite_file
      }
      format.html
      format.js
    end 
  end

  def new
    @experiment = Experiment.new()
    default_vars()
  end

  def update    
    if params.key?('reset')      
      @experiment = Experiment.find(params[:id])
      @experiment.update_attributes(:status => 0)
    end
    redirect_to(experiment_url(@experiment)) 
  end

  def create
    # Merge more data to the experiment cache   
    @experiment = Experiment.new()
    @experiment.ed = Ed.find(params[:experiment][:ed_id])
    @experiment.user = current_user
    @experiment.project = Project.find(params[:experiment][:project_id])
    @experiment.status = 0
    @experiment.runs = 0
    @experiment.failures = 0      
    testbed = params[:experiment][:nodes]["testbed"]
    @experiment.nodes = params[:experiment][:nodes]   
    if @experiment.save
      params[:experiment][:nodes].each do |k,v|
        rm = @experiment.resources_map.create(:node_id => k, :sys_image_id => v[:sys_image], :testbed_id => testbed)
      end
    end

    if @experiment.valid?
      redirect_to(@experiment)
    else
      @experiment.destroy
      @experiment.resources_map.destroy
      default_vars()
      logger.debug @allowed.inspect
      respond_with(@experiment)
    end
  end

  def destroy
    @exp = Experiment.find(params[:id])
    @exp.destroy
    redirect_to(project_path(@exp.project)) 
  end

  def prepare
    njobs = Job.all.size
    @error = nil
    if njobs > 0
      @error = "Preparation of this Experiment added to queue."
    end
    Delayed::Job.enqueue PrepareExperimentJob.new('prepare', params[:id])
  end

  def start
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
    njobs = Job.all.size
    @error = nil
    if ec.check(:prepared)
      if njobs > 0
        @error = "Preparation of this Experiment added to queue."
      end
      Delayed::Job.enqueue StartExperimentJob.new('start', params[:id])
    end
  end

  def stop
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
    if ec.check(:started) or ec.check(:prepared)
      @error = nil
      ec.stop()
    end
  end

  def stat 
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
	@experiment = Experiment.find(params[:id])
	status = @experiment.status
    slice = nil
	case 
	when (@experiment.started? or @experiment.finished?)
	  tmp = ec.experiment_status()		
	  @msg = tmp
	when (@experiment.preparing? or @experiment.prepared? or @experiment.preparation_failed?)
      tmp = ec.prepare_status()  
	  @nodes = tmp[:nodes]
	  @state = tmp[:state]
      slice = tmp[:slice]
      if params.has_key?('log') and !slice.nil?
        @log = ec.log(slice)
      elsif params.has_key?('log')      
        @log = ec.log()
      end
    end
	@status = status
	@ec = ec
  end
  
  private    
  def render_sqlite_file
    id = @experiment.id
    ec = OMF::Experiments::Controller::Proxy.new(id)
    exp_id = params[:run].nil? ? "#{id}_#{ec.runs.first}.sq3" : "#{id}_#{params[:run]}.sq3"
    results = "#{APP_CONFIG['exp_results']}#{id}/#{params[:run]}/#{exp_id}"       
    if params[:dump].nil? or params[:dump] == "false"
      send_file results, :type => "application/octet-stream", :x_sendfile => true
    else
      render :text => IO.popen("sqlite3 #{results} .dump").read
    end
  end
  
  def is_public
    begin
      project = Experiment.find(params[:id]).project
      is_assigned = project.users.where(:id => current_user.id).exists?
      if !is_assigned and project.private?        
        respond_to do |format|
          format.html { render 'shared/403' }
          format.js { render 'shared/403' }
        end
        return false
      end

    rescue ActiveRecord::RecordNotFound
      render 'shared/404', :status => 404
      return false
    end
    return true
  end

  def get_experiment_jobs()
    exp_jobs = Array.new()
    jobs = Job.all.each do |j|
      object = YAML.load(j.handler)
      if object.type == 'experiment'
        exp = Experiment.find(object.id.to_i)
        exp.attributes[:phase] = object.phase
        exp_jobs.push(exp)
      end
    end
    return exp_jobs
  end

  def default_vars()
    @projects = Project.all.select { |p| 
      !project_is_user_assigned?(p, current_user.id) ? true : false 
    }.collect { |p| 
      [p.name, p.id] 
    }
    
    @eds = Ed.all.collect { |e| 
      [e.name, e.id] 
    }
    @testbed = Testbed.first 
    service = OMF::GridServices::TestbedService.new(@testbed.id)
    @nodes = service.mapping();
    @has_map = service.has_map
    @allowed = Ed.first.allowed
  end

  def last_run(e)
    return e.runs - 1 
  end

  def fetch_results(e, run=last_run(e))
    _tmp = OMF::Experiments.results(e, {:run => run})
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
    return { :seq_num => seq_num, :results => results }
  end
end

