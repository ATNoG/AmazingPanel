class ExperimentJob < Jobs::Job
  attr_accessor :phase
  def initialize(phase, id)
    super('experiment', id.to_i)
    @phase = phase
  end  
end


