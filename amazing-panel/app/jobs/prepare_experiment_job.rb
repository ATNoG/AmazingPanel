class PrepareExperimentJob < Jobs::ExperimentJob
  def perform
    experiment = Experiment.find(@id)
    Delayed::Worker.logger.debug experiment.inspect
    ec = OMF::Experiments::Controller::Proxy.new(@id)
    ec.prepare()
    #Mailers.experiment_conclusion(experiment)
    #Mailers.experiment_conclusion(experiment, User.find_by_username("jmartins")).deliver
    #Mailers.experiment_conclusion(experiment, User.find_by_username("cgoncalves")).deliver
  end
end
