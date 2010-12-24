class Mailers < ActionMailer::Base
  default :from => "amazing@hng.av.it.pt"
  def activation(user)
    @user = user
    mail(:to => user.email,
         :subject => "Amazing Portal Account")
  end
end
