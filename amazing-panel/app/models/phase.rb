class Phase < ActiveRecord::Base
  attr_accessible :label, :number, :description

  def next
    ph = Phase.find_by_number(number + 1)
    if ph.nil? then ph = Phase.last end
    return ph
  end
  
  def back
    ph = Phase.find_by_number(number - 1)
    if ph.nil? then ph = Phase.first end
    return ph
  end

  def self.DEFINE
    return Phase.find_by_label("Define")
  end
  
  def self.MAP
    return Phase.find_by_label("Map")
  end
  
  def self.RUN
    return Phase.find_by_label("Run")
  end

end
