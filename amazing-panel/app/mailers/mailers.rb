class Mailers < ActionMailer::Base
  default :from => "amazing@atnog.av.it.pt"

  def activation(user)
    @user = user
    mail(:to => user.email,
         :subject => "[AMazINg] Portal Account")
  end

  def experiment_conclusion(experiment, user=nil)
    @user = user.nil? ? experiment.user : user;
    @experiment = experiment
    mail(:to => @user.email,
         :subject => "[AMazINg] Experiment ##{experiment.id}, Run #{experiment.runs.to_i - 1}")
  end
  
  def preparation_conclusion(experiment, user=nil)
    @user = user.nil? ? experiment.user : user;
    @experiment = experiment
    mail(:to => @user.email,
         :subject => "[AMazINg] Experiment Preparation ##{experiment.id}, Run #{experiment.runs.to_i}")
  end
end
