load 'omf.rb'
load 'omf/experiments.rb'

class ExperimentsController < ApplicationController
  include OMF::Experiments
  include Library::SysImagesHelper

  layout 'experiments'
  before_filter :authenticate
  respond_to :html, :js
  
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

  	@status = @experiment.status
    @nodes = Hash.new()
    @experiment.resources_map.each do |rm|
      @nodes[rm.node_id] = rm.sys_image_id
    end
    
    unless params.has_key?("resources")    
      #@log = OMF::Experiments::ExperimentControllerProxy.new(params[:id].to_i).log
      @log = ""
    end
    
    case 
    when params.has_key?("resources")
      @resources = @experiment.resources_map      
      @testbed = @resources.first.testbed
      @nodes = OMF::GridServices.testbed_status(@testbed.id)
    when @experiment.finished?
      ret = fetch_results(@experiment)
      @results = ret[:results]
      @seq_num = ret[:seq_num]
    end
  end
  
  def new
    @experiment = Experiment.new()
    session[:phase_status] = 0
    @current_phase = (!session[:phase].nil? ? session[:phase] : Phase.first)
    @current_phase_status = (!session[:phase].nil? ? session[:phase_status] : 0)

    if (params.key?('reset') or
        session[:phase].nil? or 
       (session[:phase] == Phase.first and session[:phase_status] == 0))
      reset()
    else
      if (@current_phase == Phase.MAP)
        @testbed = Testbed.first
        @nodes = OMF::GridServices.testbed_status(@testbed.id)
      end
      @experiment = session[:experiment][:cache]
    end
  end

  def update    
    if params.key?('reset')      
      @experiment = Experiment.find(params[:id])
      @experiment.update_attributes(:status => nil)
    end
    redirect_to(experiment_url(@experiment)) 
  end

  def create
    @current_phase = session[:phase]
    @is_last_phase = (@current_phase == Phase.last)
    if @is_last_phase
      @experiment = session[:experiment][:cache]
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
    if session[:experiment].nil?
      @experiment = Experiment.new() 
      @experiment.ed = Ed.find(params[:experiment][:ed_id])
      @experiment.phase = @current_phase
      @experiment.user = current_user
      @experiment.project = Project.find(params[:experiment][:project_id])
      session[:experiment] = Hash.new()
      session[:experiment][:cache] = @experiment
    end
    session[:experiment].merge!(params[:experiment])
    phase_step
  end

  def destroy
    @exp = Experiment.find(params[:id])
    @exp.destroy
    redirect_to(experiments_url) 
  end

  def update
    if params.key?('reset')      
      @experiment = Experiment.find(params[:id])
      @experiment.update_attributes(:status => nil)
    end
    redirect_to(experiment_url(@experiment)) 
    
    #@current_phase = session[:phase]
    #@is_last_phase = (@current_phase == Phase.last)
    #@experiment = session[:experiment][:cache]
    #session[:experiment].merge!(params[:experiment])
    #@experiment.phase = @current_phase.next()
    #phase_step
  end

  def prepare
    ec = OMF::Experiments::ExperimentControllerProxy.new(params[:id].to_i)
    @error = "Another Experiment is running"
    if ec.check(:init)
      @error = nil
      pid = fork { 
        ec.prepare() 
        render :nothing=>true
      }
	  Process.detach(pid)
    end
  end

  def stat 
    ec = OMF::Experiments::ExperimentControllerProxy.new(params[:id].to_i)
	@experiment = Experiment.find(params[:id])
	status = @experiment.status
    slice = nil
	case 
	when (status == -1 or status == 0)
      tmp = ec.prepare_status()   
	  @nodes = tmp[:nodes]
	  @state = tmp[:state]
      slice = tmp[:slice]
      if params.has_key?('log') and !slice.nil?
        @log = ec.log(slice)
      elsif params.has_key?('log')      
        @log = ec.log()
      end
	when (@experiment.started? or @experiment.finished?)
	  tmp = ec.experiment_status()		
    #@state = "PREPARED" #'XXX' REMOVE DUMMY
	  @msg = tmp;
	end
	@status = status
	@ec = ec
  end
  
  def start
    ec = OMF::Experiments::ExperimentControllerProxy.new(params[:id].to_i)
    @error = "Another Experiment is running";
    if ec.check(:prepared)
      @error = nil
	  	pid = fork { 
        ec.start()
        render :nothing => true
      }
	  Process.detach(pid)
    end
  end

  def stop
    ec = OMF::Experiments::ExperimentControllerProxy.new(params[:id].to_i)
    @error = "Another Experiment is running";
    if ec.check(:started) or ec.check(:prepared)
      @error = nil
      ec.stop()
    end
  end

  private    

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

  def fetch_results(e)
    _tmp = OMF::Experiments.results(e)
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
