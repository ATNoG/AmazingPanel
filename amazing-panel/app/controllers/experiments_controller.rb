require 'omf.rb'
require 'omf/experiments.rb'

class ExperimentsController < ApplicationController
  include OMF::GridServices
  include OMF::Experiments::Controller
  include Delayed::Backend::ActiveRecord

  include Library::SysImagesHelper
  include ProjectsHelper

  load_and_authorize_resource :experiment

  prepend_before_filter :authenticate
  respond_to :html, :js

  def queue
    @prepared = Experiment.prepared
    @queue = Experiment.jobs(current_user)
    @failed = Experiment.failed_jobs(current_user)
  end

  def delete_queue
    job = Job.try(:find, params[:job_id])
    unless job.nil?
      job.destroy
    end
    redirect_to queue_experiments_path
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
    #load_experiment
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
  	@status = @experiment.status
    @nodes = Hash.new()
    @experiment.resources_map.each do |rm|
      @nodes[rm.node_id] = rm.sys_image_id
    end

    unless params.has_key?("resources")    
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
      ret = @experiment.results(params[:run]) 
      @results = ret[:results]
      @seq_num = ret[:seq_num]
      @raw_results = ret[:runs_list]
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
      #@experiment = Experiment.find(params[:id])
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
    if @experiment.save
      params[:experiment][:nodes].each do |k,v|
        rm = @experiment.resources_map.create(:node_id => k, 
                                              :sys_image_id => v[:sys_image], 
                                              :testbed_id => testbed)
      end
    end

    if @experiment.valid?
      redirect_to(@experiment)
    else
      @experiment.destroy
      @experiment.resources_map.destroy
      default_vars()
      render :actions => 'new'
    end
  end

  def destroy
    #load_experiment
    @experiment.destroy
    redirect_to(project_path(@experiment.project)) 
  end

  def prepare    
    #load_experiment
    reset_stat_session
    @experiment.prepare
    @msg = "Experiment preparation job is added to queue."
    Rails.logger.debug("Queueing preparation experiment")
  end

  def start
    #load_experiment
    reset_stat_session
    @experiment.prepare
    @msg = "Experiment run job added to queue."
    Rails.logger.debug("Queueing run experiment")
  end 

  def stop
    #load_experiment
    @experiment.stop
  end

  def stat 
    stat = @experiment.stat(!params[:log].blank?)
	@nodes = stat[:nodes] if stat.has_key?(:nodes)
	@state = stat[:state] if stat.has_key?(:state)
    @log = ec.log(slice) if stat.has_key?(:log)
    stat_session
  end
  
  private    
  def load_experiment  
    @experiment = Experiment.find(params[:id])
  end

  def reset_stat_session
    session[:estatus] = nil
  end
  
  def stat_session
    status = @experiment.status
    if (status == ExperimentStatus.PREPARING) or (status == ExperimentStatus.STARTED)
      session[:estatus] = status
    end
  end

  def render_sqlite_file
    has_dump = !(params[:dump].nil? or params[:dump] == "false")
    ret = @experiment.sq3(params[:run], has_dump)
    unless has_dump
      return send_file ret, :type => "application/octet-stream", :x_sendfile => true
    end
    render :text => ret
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
end

