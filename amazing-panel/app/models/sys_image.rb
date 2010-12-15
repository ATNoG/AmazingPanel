class SysImage < Resource
  attr_accessible :kernel_version_os, :baseline
  belongs_to :user  
end
