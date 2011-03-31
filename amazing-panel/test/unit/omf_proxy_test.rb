require 'test_helper'
require 'omf'

class OMFProxyTest < ActiveSupport::TestCase
  include OMF::Experiments::Controller
  # Replace this with your real tests.
  test "preparation" do
    assert_raise(ArgumentError) { Proxy.new() }
  end
  
  test "start" do
  end
  
  test "stop" do
  end

  test "run" do
  end
  
  test "batch_runs" do
  end
end
