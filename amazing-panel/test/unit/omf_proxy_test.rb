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

  test "prepare_abstract" do
    ProxyClass = AbstractProxy
    c = Experiment.find(38)
    assert_raise(NotImplementedError) {
      p = c.proxy
      p.prepare()
    }
    
    assert !c.prepared?
  end

  test "start_abstract" do
    ProxyClass = AbstractProxy
    c = Experiment.find(38)
    assert_raise(NotImplementedError) {
      p = c.proxy
      p.start()
    }
    assert !c.finished?
  end
  
  test "prepare_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy 
    p.prepare()
    assert c.prepared?
  end

  test "start_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy    
    p.start()
    assert c.finished?
  end

  test "run" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    
    p.run()
    assert c.finished?
  end
  
  test "batch_runs" do
  end
end
