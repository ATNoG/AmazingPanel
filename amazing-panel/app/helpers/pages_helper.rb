module PagesHelper
  include TestbedsHelper
  
  def gravatar_for(user, options = { :size => 24})
    gravatar_image_tag(user.email.downcase, :class => 'gravatar', :align => "center", :gravatar => options)
  end  
end
