require 'spec_helper'

describe PagesController do 
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

  describe "GET 'index'" do
    it "should be sucessfull" do
      login 
      get 'index'
      response.should have_selector(".container")
    end
  end
end
