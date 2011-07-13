require 'omf.rb'
require 'omf/experiments.rb'

class ExperimentsController < ApplicationController
  include OMF::GridServices
  include OMF::Experiments::Controller
  include Delayed::Backend::ActiveRecord

  include Library::SysImagesHelper
  include ProjectsHelper
  include BranchesHelper

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
    #@experiment.set_user_repository(current_user)
    @experiment.set_proxy_author(current_user)
    change_branch()
    sort_revisions()

    @status = @experiment.status
    @code = @experiment.ed.code
    @resources = Hash.new()

    @experiment.resources_map.each do |rm|
      @resources[rm.node_id] = rm.sys_image_id
    end

    set_resources_instance_variables()
    results_for_run

    respond_to do |format|
      format.sq3 {
        render_sqlite_file
      }
      format.json
      format.html
      format.js
    end 
  end

  def resources    
    @ed = Ed.try(:find, params[:ed])
    @allowed = @ed.allowed
  end

  def new
    @experiment = Experiment.new()
    default_vars()
  end

  def update    
    @experiment.set_proxy_author(current_user)
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
    rms = transform_map(params[:experiment][:nodes])
    @experiment.set_resources_map(rms)
    if @experiment.save()
      redirect_to(@experiment)
    else
      default_vars()
      render :actions => 'new'
    end
  end

  def destroy
    @experiment.destroy
    redirect_to(project_path(@experiment.project)) 
  end

  def run
    reset_stat_session
    @experiment.set_proxy_author(current_user)
    @experiment.change(params[:commit], params[:revision])
    @experiment.run(params[:n].to_i, current_user.id, params[:revision])
    @msg = "#{params[:n]} runs in selected branch/revision <b>was added to the queue</a>.</b>"
    Rails.logger.debug("Running experiment")
  end

  def stop
    @experiment.stop
  end

  def stat 
    @experiment.set_proxy_author(current_user)
    stat = @experiment.stat(!params[:log].blank?)
    unless stat == true or stat.nil? 
      if stat != false 
    	@nodes = stat[:nodes] if stat.has_key?(:nodes)
        @state = stat[:state] if stat.has_key?(:state)
        @log = ec.log(slice) if stat.has_key?(:log)
      end
      stat_session
    end
  end
  
  private    
  def change_branch
    unless params[:branch].blank?
      @experiment.change(params[:branch], params[:revision])
    end
  end

  def sort_revisions
    @revisions = @experiment.revisions.to_a.collect{ |r| 
      { 'timestamp' => r[0], 'message' => r[1]['message'], 
        'author' => r[1]['author'] }
    }.sort!{|x,y| x['timestamp'] <=> y['timestamp']}
    @revision = params[:revision] || @experiment.repository.current.latest_commit
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
      Rails.logger.info("RESULT: #{ret}")
      return render :file => ret, :type => "application/octet-stream"
    end
    render :text => ret
  end

  def set_resources_instance_variables(embedded=true)
    @resources = @experiment.resources_map
    @testbed = @resources.first.testbed
    service = OMF::GridServices::TestbedService.new(@testbed.id);
    if embedded
      @nodes = service.mapping()
      @has_map = service.has_map()
    end
    #@nodes = OMF::GridServices.testbed_status(@testbed.id)
  end

  def results_for_run
    ret = @experiment.results(params[:run])
    @results = ret[:results]
    @seq_num = ret[:seq_num]
    @raw_results = ret[:runs_list].sort{ |x,y| y <=> x }
  end

  def default_vars
    @projects = Project.all.select { |p|
      !project_is_user_assigned?(p, current_user.id) ? true : false
    }.collect { |p|
      [p.name, p.id]
    }

    @eds = Ed.all.collect { |e|
      [e.name, e.id]
    }

    @eds = @eds.unshift(["<Your Experiment>", 0])
    @testbed = Testbed.first 
    service = OMF::GridServices::TestbedService.new(@testbed.id)
    @nodes = service.mapping();
    @has_map = service.has_map
    @allowed = Ed.available()

    #@allowed = Node.all.collect{ |n| n.id }
  end
end

