require 'test_helper'
require 'omf'
#require '_omf'

class OMFExperimentsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "oedl parser" do
    exp = Experiment.find(14)
    script = OMF::Workspace::open_ed(exp.ed.user, exp.ed.name)
    parser = OMF::Experiments::OEDLParser.new(script)
    app_metrics = parser.getApplicationMetrics()
    data = OMF::Experiments::GenericResults.new(exp)
    data.select_model_by_metric(app_metrics[0][:app], app_metrics[0][:metrics])
  end

  test "oedl_env" do
    exp = Experiment.find(14)
    script = OMF::Workspace::open_ed(exp.ed.user, exp.ed.name)
    object = OMF::Experiments::ScriptHandler.exec(14, exp.ed) 
  end
  
  # CANNOT BE TESTED, only in Development environment 'XXX'
  ## mysql doesn't support
  ## rolling back statements that change the schema (adding tables, columns
  ## etc...), executing any such statement implicitly commits the current
  ## transaction
  test "expctl-proxy" do
    expctlp = OMF::Experiments::ExperimentControllerProxy.new(15)    
    assert expctlp.prepare()
    assert expctlp.start()
    assert expctlp.stop()
  end
end
