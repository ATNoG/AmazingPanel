require 'omf.rb'
require 'omf/experiments.rb'

class ExperimentsController < ApplicationController
  include OMF::GridServices
  include OMF::Experiments::Controller
  include Delayed::Backend::ActiveRecord

  include Library::SysImagesHelper
  include ProjectsHelper


  #layout 'experiments'
  load_and_authorize_resource :experiment

  prepend_before_filter :authenticate

  #append_before_filter :is_public, :only => [:show]

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
    @exp = Experiment.find(params[:id])
    @exp.destroy
    redirect_to(project_path(@exp.project)) 
  end

  def prepare
    njobs = Job.all.size
    @msg = nil
    session[:estatus] = nil
    if njobs > 0
      @msg = "Preparation of this Experiment added to queue."
    end
    Delayed::Job.enqueue PrepareExperimentJob.new('prepare', params[:id])
  end

  def start
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
    njobs = Job.all.size
    session[:estatus] = nil
    @msg = nil
    if ec.check(:prepared)
      if njobs > 0
        @msg = "Execution of this Experiment added to queue."
      end
      Delayed::Job.enqueue StartExperimentJob.new('start', params[:id])
      Rails.logger.debug("Queueing experiment")
    end
  end

  def stop
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
    if ec.check(:started) or ec.check(:prepared)
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
    if (@status == ExperimentStatus.PREPARING) or (@status == ExperimentStatus.STARTED)
      session['estatus'] = @status
    end
  end
  
  private    
  def render_sqlite_file
    has_dump = !(params[:dump].nil? or params[:dump] == "false")
    ret = @experiment.sq3(params[:run], has_dump)
    unless has_dump
      return send_file ret, :type => "application/octet-stream", :x_sendfile => true
    end
    render :text => ret
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

