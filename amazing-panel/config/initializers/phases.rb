require 'ostruct'
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
