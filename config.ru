# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
#require 'rack/raw_upload'

#use Rack::RawUpload
run AmazingPanel::Application
