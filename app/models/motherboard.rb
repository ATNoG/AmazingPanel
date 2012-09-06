class Motherboard < ActiveRecord::Base
  attr_accessible :id, :mfr_sn, :cpu_type, :cpu_n, :cpu_hz, :hd_size, :hd_sn, :hd_status, :memory
end
