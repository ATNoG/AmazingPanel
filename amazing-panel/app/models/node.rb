class Node < ActiveRecord::Base  
  attr_accessible :id, :control_ip, :control_mac, :hostname, :hrn, :chassis_sn

  def to_s
    return hrn;
  end
end
