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
  
  test "prepare_status_local" do    
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    p.update_status_action(Status::PREPARING)
    
    data = p.status()
    
    assert_not_nil data[:nodes]
    assert_not_nil data[:state]
  end
  
  test "start_status_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    p.author = "jmartins"
    p.experiment.repository.current.create_author_file("jmartins", p.experiment.repository.current.commit, "38_28")
    p.update_status_action(Status::STARTING) #'XXX' testing purposes
    
    data = p.status()

    p.experiment.repository.current.remove_author_file("jmartins")
    assert data
  end

  test "run_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    
    p.run()
    assert c.finished?
    assert c.prepared?
  end
  
  test "prepared_run_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    p.update_status_action(Status::FINISHED_AND_PREPARED) #'XXX' testing purposes
    
    p.run_once()
    assert c.finished?
    assert c.prepared?
  end
  
  test "batchrun_prepared_local" do
    ProxyClass = LocalProxy
    c = Experiment.find(38)
    p = c.proxy
    p.update_status_action(Status::FINISHED_AND_PREPARED) #'XXX' testing purposes
    
    p.batch_run(2)
    assert c.finished?
    assert c.prepared?
  end  
end
