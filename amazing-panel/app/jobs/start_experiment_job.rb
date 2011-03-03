class Jobs::StartExperimentJob < Jobs::ExperimentJob
  def perform              
    #@@logger = Logger.new("#{Rails.root.join("log/"+@id.to_s+"-proxylog.log")}")
    #ec = OMF::Experiments::Controller::Proxy.new(@id)
    #ec.prepare()
    experiment = Experiment.find(@id)
    puts experiment.inspect
    #Mailers.experiment_conclusion(experiment)
    #Mailers.experiment_conclusion(experiment, User.find_by_username("jmartins")).deliver
    #Mailers.experiment_conclusion(experiment, User.find_by_username("cgoncalves")).deliver
  end
end
