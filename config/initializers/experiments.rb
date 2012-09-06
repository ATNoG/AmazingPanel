require 'ostruct'
require 'omf'

ExperimentPhases = {
  :define => OpenStruct.new({
    :order => 1,
    :description => "Define your experiment script and parameters"
  }),
  :map => OpenStruct.new({
    :order => 2,
    :description => "Map your resources in the necessary nodes for the experiment"
  }),
}

ExperimentStatus = OpenStruct.new({
  :UNINITIALIZED => 0,
  :PREPARING => 1,
  :PREPARED => 2,
  :STARTED => 3,
  :FINISHED => 4,
  :FINISHED_AND_PREPARED => 5,
  :PREPARATION_FAILED => -1,
  :EXPERIMENT_FAILED => -2,
});

ProxyClass = OMF::ExperimentsController::LocalProxy
