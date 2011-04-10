module Jobs
  class Job
    attr_accessor :id, :type
    def initialize(type,id)
      @id = id
      @type = type
    end
  end

  class ExperimentJob < Jobs::Job
    attr_accessor :phase
    def initialize(phase, id)
      super('experiment', id.to_i)
      @phase = phase
    end  
  end
end
