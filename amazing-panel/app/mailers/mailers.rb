class Mailers < ActionMailer::Base
  default :from => "amazing@hng.av.it.pt"

  def activation(user)
    @user = user
    mail(:to => user.email,
         :subject => "[AMazINg] Portal Account")
  end

  def experiment_conclusion(user, experiment)
    @user = user
    @experiment = experiment
    mail(:to => user.email,
         :subject => "[AMazINg] Experiment ##{experiment.id}, Run #{experiment.runs}")
  end
end
