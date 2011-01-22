class SysImage < Resource
  attr_accessible :kernel_version_os, :baseline, :size
  belongs_to :user  
end
