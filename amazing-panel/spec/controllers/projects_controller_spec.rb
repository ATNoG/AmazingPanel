require 'spec_helper'

describe ProjectsController do
  include Devise::TestHelpers

  def mock_users(stubs={})
    @user ||= mock_model(User, stubs).as_null_object
  end

  def login
    attr = { :username => "jmartins", :email => "joaolemos@ua.pt" }
    request.env["warden"] = mock(Warden, :authenticate => mock_users(attr), 
                                         :authenticate! => mock_users(attr),
                                         :authenticate? => mock_users(attr))
  end

  render_views
  
  describe "GET all redirect_to sign_in" do
    it "should be successfull" do
      get 'index'
      response.should be_redirect
      get 'show', :id => 3
      response.should be_redirect
      login
      puts Project.all.inspect
      get 'show', :id => 3
      response.should have_selector(".container")
    end
  end
end
