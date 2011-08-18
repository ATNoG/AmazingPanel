module Library::LibraryHelper
 
  def download_action(sys_image, options={})
    return add_image_action(sys_image_path(sys_image, :format => "ndz"), "download.png", "Download", options)
  end

end
