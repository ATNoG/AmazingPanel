class RunExperimentJob < Jobs::ExperimentJob
  def perform              
    ec = OMF::Experiments::Controller::Proxy.new(@id)
    experiment = Experiment.find(@id)
    unless experiment.prepared?
      ec.prepare()
    end
    ec.start()
    Delayed::Worker.logger.debug experiment.inspect
  end
end
