module PagesHelper
  def gravatar_for(user, options = { :size => 24})
    gravatar_image_tag(user.email.downcase, :alt => user.username, :class => 'gravatar', :align => "center", :gravatar => options)
  end  
end
