AmazingPanel::Application.routes.draw do
  #devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }  
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }    
  
  scope :module => "users" do
    resources :users, :only => [:index, :show, :destroy, :edit, :update]
  end
  
  resources :projects, :path => "workspaces" do
    member do
      get 'users'
      get 'assign'
      put 'user/:user_id', :action => "assign_user"
      put 'user/:user_id/leader', :action => "make_leader"      
      delete 'user/:user_id', :action => "unassign_user"
    end
  end
  
  scope :module => "library" do
    resources :library, :only => [:index]
    
    resources :eds do
      post 'code', :action => 'code', :on => :collection
      get 'doc', :action => 'doc', :on => :collection
    end

    resources :sys_images do
      post 'image', :action => 'image', :on => :member
    end
    
    resources :applications
  end
  
  resources :testbeds do
    get '/nodes/:node_id/info', :action => "node_info", :as => "info", :on => :member
    put '/nodes/:node_id/toggle', :action => "node_toggle", :as => "toggle", :on => :member
    put '/nodes/:node_id/maintain', :action => "node_toggle_maintain", :as => "maintain", :on => :member
  end
  
  scope :module => "admin", :as => "admin" do
    resources :admin, :path => "admin", :only => [:index]
    devise_for :users , :path => "admin/users", :controllers => { :registrations => "admin/registrations" }    
    resources :users, :path => "admin/users" do
      put '/activate', :action => "activate"
    end    
    resources :sys_images, :path => "admin/sys_images"  
    resources :testbeds, :path => "admin/testbeds"  do
      get '/nodes/:node_id/info', :action => "node_info", :as => "info", :on => :member
      put '/nodes/:node_id/toggle', :action => "node_toggle", :as => "toggle", :on => :member
    end
  end
 
  resources :experiments do
    get 'run', :action => 'run', :on => :member
    #get 'prepare', :action => 'prepare', :on => :member
    #get 'start', :action => 'start', :on => :member
    get 'stop', :action => 'stop', :on => :member
    get 'stat', :action => 'stat', :on => :member
    get 'queue', :action => 'queue', :on => :collection
    delete 'queue/:job_id', :action => 'delete_queue', :as => "delete_queue", :on => :collection
    resources :branches, :except => [:index, :edit, :new] do 
      member do 
        post 'clone', :action => 'clone'
        post 'commit', :action => 'commit'
      end
    end
  end
  
  match 'javascripts/application.js' => 'pages#application'
  match 'stylesheets/custom.css' => 'pages#custom'
  
  root :to => "pages#index"
end
