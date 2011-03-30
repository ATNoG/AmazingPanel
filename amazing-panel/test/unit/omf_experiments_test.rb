require 'test_helper'
require 'omf'

class OMFExperimentsTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "oedl_env" do
    id = 35
    exp = Experiment.find(id)
    object = OMF::Experiments::ScriptHandler.exec(exp.id, exp.ed) 
    assert_not_nil object
  end
  
  test "oedl_reference" do
    reference = OMF::Experiments::ScriptHandler.scanRepositories()
    #pp reference.keys()
    assert !reference.blank?
    
    app = OMF::Experiments::ScriptHandler.getDefinition("test:app:otr2")
    assert !app.blank?
    assert !app.properties.empty?
    pp app.properties.keys()
  end  

  test "oedl_scan_repo" do 
    apps = OMF::Experiments::ScriptHandler.scanRepositories()
    assert !apps.keys().empty?()
    pp apps.keys()
  end
  
  test "oedl_scan_app" do 
    #@apps = OMF::Experiments::ScriptHandler.getDefinition("test:app:otg2")
    #pp @apps
    @app = OMF::Experiments::ScriptHandler.getDefinition("test:app:otr2")
    assert @app.properties[:repository][:apps].has_key?("test:app:otr2")
    
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
    app = OMF::Experiments::OEDL::Generator.new();    
    p = params[:applications]["my:sample"]
    args = ["my:sample", p["name"], p]
    code = app.from_sexp(:createApplicationDefinition, args)
    @app = OMF::Experiments::ScriptHandler.getDefinition(nil, code)
    assert @app.properties[:repository][:apps].has_key?("my:sample")
    pp @app
  end

  test "oedl_gen" do
      params = HashWithIndifferentAccess.new({ 
        "meta" => {
          "groups" => { 
            "0" => {
              "name" => "default", 
              "nodes" => ["omf.amazing.node1","omf.amazing.node2"]},
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
                  "uri" => "test:app:otr3",
                  "measures" => { "selected" => "udp_in"}, 
                  "options" =>{
                    "selected" => ["udp:local_host", "udp:local_port"], 
                    "properties" => {"udp:local_host"=>"192.168.0.1", "udp:local_port"=>"4000"}
                  }
                },
                "1" =>{
                  "uri" => "test:app:otr2",
                  "measures" => { "selected" => "udp_in"}, 
                  "options" =>{
                    "selected" => ["udp:local_host", "udp:local_port"], 
                    "properties" => {"udp:local_host"=>"192.168.0.2", "udp:local_port"=>"3000"}
                  }
                }, 
                "2" =>{
                  "uri" => "test:app:echo",
                  "measures" => "",
                  "options" => ""
                }
              }
            }
        }, "properties" => { 
          "duration" => 30, 
          "network" => "off",
          "testbed" => { 
            "id" =>Testbed.first.id, 
            "name" => Testbed.first.name 
          }
        }
      }})
      repos = OMF::Experiments::ScriptHandler.scanRepositories()
      script = OMF::Experiments::OEDL::Generator.new({ :meta => params, :repository => repos })
      code = script.to_s();
      assert_not_nil code
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
    app = OMF::Experiments::OEDL::Generator.new();    
    params[:applications].each do |uri, p|
      args = [uri, p[:name], p]
      appdef = app.from_sexp(:createApplicationDefinition, args)
      assert_not_nil appdef
      puts appdef
    end
  end

  test "oedl_timeline_gen" do
    params = HashWithIndifferentAccess.new({
      :timeline => [
        {:group => "sample", :start => 10, :stop => 24 },
        {:group => "otg2", :start => 20, :stop => 25 },
        {:group => "otg2", :start => 22, :stop => -1, :command => "echo done" },
        {:group => "iperf", :start => 27, :stop => 31 }
      ]})
    app = OMF::Experiments::OEDL::Generator.new(:meta => params);
    assert_not_nil code = Ruby2Ruby.new().process(app.all_up())
    puts code

    params = HashWithIndifferentAccess.new({
      "meta" => { 
        "properties" => { 
            "duration" => 30, 
            "network" => "on",
            "testbed" => { 
              "id" => 0, 
              "name" => 'amazing' 
            }
        }
      }, :timeline => [
        {:group => "otg2", :start => 20, :stop => -1, :command => "echo otr2" },
        {:group => "otg2", :start => 22, :stop => -1, :command => "echo otg3" },
        {:group => "iperf", :start => 27, :stop => -1, :command => "echo iperf" }
      ]})
    app = OMF::Experiments::OEDL::Generator.new(:meta => params);
    assert_not_nil code = Ruby2Ruby.new().process(app.all_up())

    puts code
  end

  # CANNOT BE TESTED, only in Development environment 'XXX'
  ## mysql doesn't support
  #   rolling back statements that change the schema (adding tables, columns
  #   etc...), executing any such statement implicitly commits the current
  #   transaction
  #test "expctl-proxy" do
  #  expctlp = OMF::Experiments::ExperimentControllerProxy.new(15)    
  #  assert expctlp.prepare()
  #  assert expctlp.start()
  #  assert expctlp.stop()
  #end
end
