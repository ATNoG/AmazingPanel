require 'logger'

class PrepareExperimentJob < Jobs::ExperimentJob
  def perform
    #ec = OMF::Experiments::Controller::Proxy.new(@id)
    #ec.prepare()    
    experiment = Experiment.find(@id)
    Rails.logger.debug experiment.inspect
    #Mailers.experiment_conclusion(experiment)
    #Mailers.experiment_conclusion(experiment, User.find_by_username("jmartins")).deliver
    #Mailers.experiment_conclusion(experiment, User.find_by_username("cgoncalves")).deliver
  end
end
