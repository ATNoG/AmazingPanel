class PrepareExperimentJob < Jobs::ExperimentJob
  def perform
    Delayed::Worker.logger.debug experiment.inspect
    ec = OMF::Experiments::Controller::Proxy.new(@id)
    ec.prepare()
    experiment = Experiment.find(@id)
    #Mailers.preparation_conclusion(experiment)
    Mailers.preparation_conclusion(experiment, User.find_by_username("jmartins")).deliver
    #Mailers.preparation_conclusion(experiment, User.find_by_username("cgoncalves")).deliver
  end
end
