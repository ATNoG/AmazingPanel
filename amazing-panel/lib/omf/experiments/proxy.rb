module OMF::Experiments::Controller

  """
    Status Enum, but can be used as a collection
    Contains all possible proxy status values
  """
  class Status
    def Status.add_item(key,value)
      @hash ||= {}
      @hash[key]=value
    end

    def Status.const_missing(key)
      @hash[key]
    end

    def Status.index(value)
      @hash.index(value)
    end

    def Status.each
      @hash.each {|key,value| yield(key,value)}
    end 

    Status.add_item :UNINITIALIZED, 0
    Status.add_item :PREPARING, 1
    Status.add_item :PREPARED, 2
    Status.add_item :STARTING, 3
    Status.add_item :FINISHED, 4
    Status.add_item :FINISHED_AND_PREPARED, 5
    Status.add_item :PREPARATION_FAILED, -1    
    Status.add_item :EXPERIMENT_FAILED, -2
  end

  """
    When activating the blocking mode, this should be the base
    exception class
  """
  class ControllerProxyError < Exception
    attr_accessor :value
    def initialize(value)
      @value = value
    end
  end

  """
    Helper functions for proxy
  """
  module ProxySupport
    def setup_logger(id)
      logger = Logger.new("#{Rails.root.join("log/#{id}-proxy.log")}")
      logger.formatter = proc { |severity, datetime, progname, msg|
        "#{datetime} #{severity} -- #{msg}\n"
      }
      return logger
    end
  end

  """
  * A Proxy must have four necessary methods: prepare, start, stop, run, batch_run
    _action and _state methods were developed for easy proxy extensions made easy to 
    change the resources available for auditoring. For instance, instead instead of commands
    one could create a HTTPProxy which asks for the Experiment Controller to manage logging,
    start, stop and preparation of the experiment. The proxy will need nothing but to query 
    the http wrapper, with no need to redefine the whole workflow of the experiment, but instead
    only the location of the resources.
  """
  class AbstractProxy
    include ProxySupport
    attr_reader :experiment, :author
    attr_writer :author

    def initialize(args={})
      raise ArgumentError.new("No experiment provided") if args[:experiment].nil?
      raise ArgumentError.new("Wrong type: ") unless args[:experiment].class == Experiment

      # Experiment Model
      @experiment = args[:experiment]      

      # Experimenter running the ed. Default: Creator of the Ed
      #@author = @experiment.user.username
      @author = @experiment.user.username

      # Default Flags
      @flags = {
        :blocking => false
      }

      # Experiment ID
      @id = @experiment.id

      # Logger of the proxy
      @logger = setup_logger(@id)

      # Blocking means with exceptions
      @flags[:blocking] = args[:blocking] unless args[:blocking].blank?
    end

    def prepare
      info("Unpreparing experiments")

      # Unprepare all experiments
      # - One Experiment at a time -
      unprepare_all_action()

      info("Cleaning all temporary files")

      # Clean all log files
      clean_action()

      info("Updating status")

      # Update status to Status::PREPARING
      update_status_action(Status::PREPARING)
      
      debug("Current Status = #{Status.index(@experiment.status)}")

      images = {}
      # Group Resource Maps by system image
      @experiment.resources_map.each do |rm|
        images[rm.sys_image.id] = (images[rm.sys_image.id] || []).push(rm.node)
      end

      images.each do |img, nodes|
        info("Loading SysImage ##{img} on #{nodes.collect{|n| n.hrn}.join(",")}")
        
        # Load each sysimage to resource(s)
        ret = load_resource_action(SysImage.find(img), nodes)
      end
      
      info("Checking preparation state...")
      state = get_current_state(Status::PREPARING)
      return cond_set_status(state) 
    end

    def start
      #   Generate and change the runs of experiment
      #   Necessary to have different runs to generate different ids, 
      #   so it don't inflict any instability on OML Server and AggMgr
      generate_id()          
      info("Experiment #{@id} EID generated: #{@eid}")      
      
      @experiment.repository.current.create_author_file(@author, @experiment.repository.current.commit, @eid)
      info("Created author_file for Experiment #{@id}")

      # Update status to Status::STARTING
      update_status_action(Status::STARTING)
      
      debug("Current Status = #{Status.index(@experiment.status)}")
      info("Starting Experiment #{@id} Run = #{@run}")      
      
      # Issues the start action
      if !start_action()
        return cond_set_status("FAILED")
      end

      info("Fetching results")

      # Fetch results
      files = load_results_action()
      if files.blank?
        error("No files available from experiment")
        return cond_set_status("FAILED")
      end

      @experiment.repository.current.save_run(@run, files)
      info("Run #{@run} files copied to branch <#{@experiment.current}> @commit=#{"dummy"}")

      @experiment.repository.current.remove_author_file(@author)

      info("Checking experiment state...")
      state = get_current_state(Status::STARTING)
      return cond_set_status(state)
    end

    # status method to get all the current status of the 
    # undergoing experiment
    def status
      if @experiment.preparing?
        return status_prepare_action
      elsif @experiment.started?
        return status_experiment_action
      end
    end

    def run_once
      puts "RUN_ONCE"
      ret = @experiment.status
      ret = prepare() unless @experiment.prepared?
      ret = start() unless @experiment.started? or ret < 0
      return (@experiment.prepared? and @experiment.finished?)
    end

    def batch_run(n=1)
      info("Batch with #{n} runs")
      for i in 1..n
        debug("Run ##{i}")
        err = run_once()
        break unless err
      end
    end
    
    def update_status_action(v)
      @experiment.update_attributes!(:status => v)
    end

    protected
    def generate_id()      
      # Experiment Runs
      @run = @experiment.repository.current.next_run(true)
      @eid = "#{@id}_#{@run}"
    end    

    """
      _action() are the main actions of the proxy, 
      no return value
    """
    def unprepare_all_action
      Experiment.where(:status => 5).update_all(:status => 4) 
      Experiment.where(:status => 2).update_all(:status => 0) 
    end
    
    def status_prepare_action
      data = prepare_status_data()
      nodes = check_nodes_status(data)
      state = check_overall_status(data)
      return { :nodes => nodes, :state => state }
    end

    def status_experiment_action()
      author_data = @experiment.repository.current.load_author_file(@author)
      @eid = author_data['experiment']['eid']
      return check_experiment_status(start_state())
    end

    def clean_action
      raise NotImplementedError.new("clean_action() not implemented")
    end

    def load_resource_action(img, nodes)
      raise NotImplementedError.new("load_resource_action() not implemented")
    end
    
    def start_action()
      raise NotImplementedError.new("start_action() not implemented")
    end

    def load_results_action
      raise NotImplementedError.new("load_results_action() not implemented")
    end
    
    def prepare_status_data
      raise NotImplementedError.new("start_state() not implemented")
    end

    """
      _state() procedures are called when finishing the approppriate actions.
      Normally it will be a logfile returning its state if it was succedded or not
    """
    # Called when ResourceMaps loading is finished
    def prepare_state
      raise NotImplementedError.new("prepare_state() not implemented")
    end

    # Called when experiment finishes
    def start_state
      raise NotImplementedError.new("start_state() not implemented")
    end

    def get_current_state(status)
      case status
      when Status::PREPARING
        prepare_state
      when Status::STARTING
        start_state
      end
    end

    # get node status 
    # returns a Hash :
    # * node_id = { :progress_value, :state, :msg }
    def check_nodes_status(status_data)    
      raise NotImplementedError.new("prepare_state() not implemented")
    end

    # Preparation is also considerer an experiment, in OMF
    # This helper will help to check overall preparation status
    def check_overall_status(status_data)      
      raise NotImplementedError.new("prepare_state() not implemented")
    end
    
    def check_experiment_status(status_data)      
      raise NotImplementedError.new("check_experiment_status() not implemented")
    end

    # Conditional Set status, when a prepare, start finished its main action
    def cond_set_status(state, preparing=false)
      _status = nil
      case state
      when "PREPARING"
        value = Status::PREPARING
      when "PREPARED"
        value = Status::PREPARED
      when "DONE"
        value = Status::FINISHED_AND_PREPARED
      else
        if preparing
          value = Status::PREPARATION_FAILED
        else
          value = Status::EXPERIMENT_FAILED
        end
      end
      update_status_action(value)
      
      # raise if it is in blocking mode
      if (value < 0) and !@flags[:blocking].blank?
        error("Experiment failed!")
        raise ControllerProxyError.new(value) 
      else
        info("Experiment success.")
      end
      
      return value
    end
        
    private
    def info(msg) @logger.info(msg) end
    def error(msg) @logger.error(msg) end
    def debug(msg) @logger.debug("\t"+msg) end
  end
end

require 'omf/experiments/proxy/local'
