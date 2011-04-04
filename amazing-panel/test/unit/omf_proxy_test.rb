require 'test_helper'
require 'omf'

class OMFProxyTest < ActiveSupport::TestCase
  include OMF::Experiments::Controller
  # Replace this with your real tests.
  test "foundations" do
    assert_raise(ArgumentError) { AbstractProxy.new() }
    assert_not_nil c = Experiment.find(38).proxy
    assert c.experiment.id == 38
  end

  test "prepare" do
    c = Experiment.find(38).proxy
    c.prepare()
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
