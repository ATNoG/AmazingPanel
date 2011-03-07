class StopExperimentJob < Jobs::ExperimentJob
  def perform              
    ec = OMF::Experiments::Controller::Proxy.new(@id)
    ec.stop()
    experiment = Experiment.find(@id)
    Delayed::Worker.logger.debug experiment.inspect
  end
end
