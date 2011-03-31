module OMF::Experiments::Controller
  module Status
    UNINITIALIZED = 0
    PREPARING = 1
    PREPARED = 2
    STARTED = 3
    FINISHED = 4
    FINISHED_AND_PREPARED = 5
    PREPARATION_FAILED = -1
    EXPERIMENT_FAILED = -2    
  end

  class Proxy
    def initialize(args={})
      raise ArgumentError.new("No experiment id provided.") if args[:id].nil?
      @id = args[:id].to_i
    end

    def prepare
      raise NotImplementedError.new("Run not yet implemented")
    end

    def start
      raise NotImplementedError.new("Run not yet implemented")
    end

    def run
      raise NotImplementedError.new("Run not yet implemented")
    end    

    def stat      
      raise NotImplementedError.new("Run not yet implemented")
    end

    def batch_run(n=1)
    end

    protected
    def clean
    end

    def results
    end
  end
end
