class RunExperimentJob < Jobs::ExperimentJob
  attr_accessor :user, :runs, :branch, :commit
  def initialize(id, user, runs, commit, branch)
    raise ArgumentError.new("Runs must be a positive integer") if (runs <= 0)
    super('experiment', id.to_i)
    @runs = runs
    @branch = branch
    @commit = commit
    @user = user
    Rails.logger.debug("Experiment ##{id} : runs=#{runs}, commit=#{commit}, branch=#{branch}, user=#{user}")
  end

  def perform      
    u = User.find(@user)
    experiment = Experiment.find(@id)
    experiment.change(@branch, @revision)
    experiment.load_proxy()  
    experiment.proxy.author = u.username
    next_run = experiment.repository.current.next_run
    experiment.proxy.batch_run(@runs)    
    Mailers.run_conclusion(experiment, next_run, @runs, @commit, @branch)
    #Delayed::Worker.logger.debug experiment.inspect
  end
end
