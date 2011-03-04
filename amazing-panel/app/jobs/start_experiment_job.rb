class Jobs::StartExperimentJob < Jobs::ExperimentJob
  def perform              
    ec = OMF::Experiments::Controller::Proxy.new(@id)
    #ec.start()
    experiment = Experiment.find(@id)
    Delayed::Worker.logger.debug experiment.inspect
    #Mailers.experiment_conclusion(experiment)
    #Mailers.experiment_conclusion(experiment, User.find_by_username("jmartins")).deliver
    #Mailers.experiment_conclusion(experiment, User.find_by_username("cgoncalves")).deliver
  end
end
