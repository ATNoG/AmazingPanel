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
              "properties" => {
                "net" => { 
                  "w0" => { 
                    "mode" => "6", 
                    "type" => "g", 
                    "essid" => "helloworld" ,
                    "ip" => ""
                  }
                }
              }, "applications" => {
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
        }, "properties" => { 
          "duration" => 30, 
          "network" => "on",
          "testbed" => { 
            "id" =>Testbed.first.id, 
            "name" => Testbed.first.name 
          }
        }
      }})
      script = OMF::Experiments::OEDL::Script.new(params)
      code = script.to_s();
      puts code
  end

  test "oedl_app_gen" do
    params = HashWithIndifferentAccess.new({
      "applications" => {
         "my:sample" =>{
           "name" => "sample",
           "measures" => { "general" => { "throughtput" => :long, "rssi" => :long } }, 
           "options" =>{
             "path" => "/usr/bin/sample",
             "version" => "0.0.1",
             "appPackage" => "/home/jon/Programs/share/sample.tar.gz",
             "shortDescription" => "Sample Application",
             "description" => "Sample Application",
             "properties" => {
                "receivers" => {
                  "description" => "Number of Receivers",
                  "mnemonic" => "-r",
                  "options" => {  "dynamic" => "false", "type" => "integer", "order" => "0"  }
                },                 
                "senders" => {
                  "description" => "Number of Senders",
                  "mnemonic" => "-s",
                  "options" => {  "dynamic" => "false", "type" => "integer", "order" => "1"  }
                }, 
             }
           }
         }
      }
    })
    app = OMF::Experiments::OEDL::Script.new();    
    params[:applications].each do |uri, p|
      args = [uri, p[:name], p]
      puts app.from_sexp(:createApplicationDefinition, args)
    end
  end

  test "oedl_timeline_gen" do
    params = HashWithIndifferentAccess.new({
      :timeline => [
        {:group => "sample", :start => 10, :stop => 30 },
        {:group => "otg2", :start => 20, :stop => 20 },
        {:group => "iperf", :start => 15, :stop => 31 }
      ]})
    app = OMF::Experiments::OEDL::Script.new(params);
    puts Ruby2Ruby.new().process(app.all_up())
  end
  
  # CANNOT BE TESTED, only in Development environment 'XXX'
  ## mysql doesn't support
  #   rolling back statements that change the schema (adding tables, columns
  #   etc...), executing any such statement implicitly commits the current
  #   transaction
  test "expctl-proxy" do
    expctlp = OMF::Experiments::ExperimentControllerProxy.new(15)    
    assert expctlp.prepare()
    assert expctlp.start()
    assert expctlp.stop()
  end
end
