require 'test_helper'
require 'omf'

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

  test "oedl_gen" do
      params = HashWithIndifferentAccess.new({ 
        "meta" => {
          "groups" => { 
            "0" => {
              "name" => "default"}, 
            "1" => {
              "name" => "__group_n24_", 
              "nodes" => ["omf.amazing.node1","omf.amazing.node2"],
              "applications" => {
                "0" =>{
                  "uri" => "test:app:otr2",
                  "measures" => { "selected" => "udp_in"}, 
                  "options" =>{
                    "selected" => ["udp:local_host", "udp:local_port"], 
                    "properties" => {"udp:local_host"=>"192.168.0.2", "udp:local_port"=>"3000"}
                  }
                }
              }
            }
        }, "properties" => { "duration" => 30, "testbed" => { "id" =>Testbed.first.id, "name" => Testbed.first.name }
        }
      })
      script  =OMF::Experiments::OEDL::OEDLScript.new(params[:meta])
      code = script.toRuby();
      puts code
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
