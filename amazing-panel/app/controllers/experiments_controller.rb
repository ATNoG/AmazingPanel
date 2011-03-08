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
    #not_init = Experiment.where(:status => nil) 
    #@experiments_not_init = not_init
    @prepared = Experiment.prepared
    
    @queue = Array.new()
    jobs = Job.all.each do |j|
      object = YAML.load(j.handler)
      if object.type == 'experiment'
        exp = Experiment.find(object.id.to_i)
        exp.attributes[:phase] = object.phase
        @queue.push(exp)
      end
    end
    unless jobs
      @queue = jobs
    end
    #@num_exps = @experiments.size + @experiments_prepared.size
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
        id = @experiment.id
        exp_id = params[:run].nil? ? "#{id}_#{ec.runs.first}.sq3" : "#{id}_#{params[:run]}.sq3"
        #render :file => "#{APP_CONFIG['exp_results']}#{id}/#{params[:run]}/#{exp_id}"
        results = "#{APP_CONFIG['exp_results']}#{id}/#{params[:run]}/#{exp_id}"       
        if params[:dump].nil? or params[:dump] == "false"
          send_file results, :type => "application/octet-stream", :x_sendfile => true
        else
          render :text => IO.popen("sqlite3 #{results} .dump").read
        end
      }
      format.html
      format.js
    end 
  end
  
  def new
    @experiment = Experiment.new()
    session[:phase_status] = 0
    @current_phase = (!session[:phase].nil? ? session[:phase] : Phase.first)
    @current_phase_status = (!session[:phase].nil? ? session[:phase_status] : 0)
    if (params.key?('reset'))
      @projects = Project.all.select { |p| !project_is_user_assigned?(p, current_user.id) ? true : false }.collect { |p| [p.name, p.id] }
      @eds = Ed.all.collect {|e| [ e.name, e.id ] }
      session[:experiment] = nil
      session[:phase] = Phase.first
      session[:phase_status] = 0
    elsif (session[:phase].nil? or 
       (session[:phase] == Phase.first and session[:phase_status] == 0))
      @projects = Project.all.select { |p| !project_is_user_assigned?(p, current_user.id) ? true : false }.collect { |p| [p.name, p.id] }
      @eds = Ed.all.collect {|e| [ e.name, e.id ] }
      unless session[:experiment].nil? and session[:experiment][:cache].nil?
        @experiment = session[:experiment][:cache]
      end
      reset()
    else
      if (@current_phase == Phase.MAP)
        @testbed = Testbed.first
        service = OMF::GridServices::TestbedService.new(@testbed.id)
        #@nodes = OMF::GridServices.testbed_status(@testbed.id)
        @nodes = service.mapping();
        @has_map = service.has_map
      end
      @experiment = session[:experiment][:cache]
      @allowed = session[:experiment][:allowed]
    end
  end

  def update    
    if params.key?('reset')      
      @experiment = Experiment.find(params[:id])
      @experiment.update_attributes(:status => 0)
    end
    redirect_to(experiment_url(@experiment)) 
  end

  # Handles all the phases in Experiment Creation
  def create
    @current_phase = session[:phase]
    @is_last_phase = (@current_phase == Phase.last)
    
    # Create Experiment in the last phase
    if @is_last_phase
      @experiment = session[:experiment][:cache]
      @experiment.runs = 0
      @experiment.failures = 0
      @experiment.save
      testbed = session[:experiment]["nodes"]["testbed"]
      session[:experiment]["nodes"].each do |k,v|
        unless k == "testbed"
          node = Node.find(k)
          sysimage = SysImage.find(v["sys_image"])
          testbed_m = Testbed.find(testbed)
          rm = @experiment.resources_map.create(:node => node, :sys_image => sysimage, :testbed => testbed_m)
        end
      end
      session[:experiment].delete(:cache)
      session[:experiment][:phase] = Phase.RUN
      session[:experiment][:id] = @experiment.id          
      return redirect_to(experiment_url(@experiment)) 
    end

    # Caches experiment for future phase
    if session[:experiment].nil?
      @experiment = Experiment.new() 
      @experiment.ed = Ed.find(params[:experiment][:ed_id])
      @experiment.phase = @current_phase
      @experiment.user = current_user
      @experiment.project = Project.find(params[:experiment][:project_id])
      @experiment.status = 0
      session[:experiment] = Hash.new()
      session[:experiment][:cache] = @experiment
    end

    # Merge more data to the experiment cache   
    @experiment = Experiment.new()
    @experiment.errors.clear()
    validation
    if @experiment.errors.any?
      #render :action => :new
      redirect_to(new_experiment_path)
    else
     session[:experiment].merge!(params[:experiment])
     phase_step
    end
  end

  def destroy
    @exp = Experiment.find(params[:id])
    @exp.destroy
    redirect_to(project_path(@exp.project)) 
  end

  def prepare
    ec = OMF::Experiments::Controller::Proxy.new(params[:id].to_i)
    njobs = Job.all.size
    @error = nil
    if njobs > 0
      @error = "Preparation of this Experiment added to queue."
    end

    Delayed::Job.enqueue PrepareExperimentJob.new('prepare', params[:id])
    #if ec.check(:init)
    #  @error = nil
    #  Delayed::Job.enqueue PrepareExperimentJob.new('prepare', params[:id])
    #end
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

  def reset
    session[:phase] = Phase.first
    session[:phase_status] = 0
    session[:experiment] = nil
  end

  def phase_step(backwards=false)    
    if !@is_last_phase
      session[:phase] = @current_phase.next()
    end
    session[:phase_status] = 1
    redirect_to new_experiment_path
  end

  def validation
    @experiment = session[:experiment][:cache]
    @experiment.errors.clear()
    case
    # validation on DEFINE script phase
    #   * checks for emptiness of the ed
    #   * checks for nodes valid on groups definition
    #   * defines the allowed nodes to map in the next phase
    when (@current_phase == Phase.DEFINE)
      begin 
        ed = Ed.find(@experiment.ed)
        ed_content = OMF::Workspace.open_ed(ed.user, "#{ed.id.to_s}.rb")
        p = OMF::Experiments::ScriptHandler.exec(-1, ed)
        nodes = Array.new()

        p.properties[:groups].each do |k,v|
          hrn = v[:selector]
          n = Node.find_by_hrn!(hrn)
          nodes.push(n.id.to_i)    
        end
        session[:experiment][:allowed] = nodes
      rescue
        if ed_content.size == 0
          @experiment.errors[:ed] = t("errors.experiment.ed.empty")
        else
          @experiment.errors[:nodes] = t("errors.experiment.nodes.invalid")
        end
        session[:experiment][:cache] = @experiment
        return false
      end
    when (@current_phase == Phase.MAP)
      begin
        testbed = Testbed.find(params[:experiment]["nodes"]["testbed"].to_i)
        nodes = Array.new()
        allowed = session[:experiment][:allowed]
        if testbed.nil?
          @experiment.errors[:testbed] = t("errors.experiment.testbed")
          return false
        end
        if params[:experiment]["nodes"].length <= 1
          @experiment.errors[:resources_map] = t("errors.experiment.resources_map.empty")
          return false
        end
        params[:experiment]["nodes"].each do |k,v|
          unless k == "testbed"
            if k.to_i 
              node = Node.find(k)
              if allowed.index(node.id).nil?
                #@experiment.errors[:nodes] = ": only #{allowed.sort.join(",")} allowed."
                @experiment.errors[:nodes] = t("errors.experiment.nodes.allowed", :nodes => allowed.sort.join(","))
                return false
              end
              sysimage = SysImage.find(v["sys_image"])              
              nodes.push(node.id.to_i)
            end 
          end
        end  
        if nodes.length != allowed.length
          missing = Array.new(allowed).delete_if { |x| !nodes.index(x).nil?  } 
          #@experiment.errors[:nodes] = "#{missing.sort.join(",")} missing system image."
          @experiment.errors[:nodes] = t("errors.experiment.nodes.missing", :nodes => missing.sort.join(","))
        end
      rescue
        @testbed = Testbed.first
        @allowed = session[:experiment][:allowed]
        @nodes = OMF::GridServices::TestbedService.new(@testbed.id).mapping();
        @experiment.errors[:resources_map] = t("errors.experiment.resources_map.invalid")
        return false
      end
    end

    return true
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
