AmazingPanel::Application.routes.draw do
  #devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }  
  devise_for :users, :controllers => { :sessions => "users/sessions", :registrations => "users/registrations" }    
  
  scope :module => "users" do
    resources :users, :only => [:index, :show, :destroy]
  end
  
  resources :projects do
    member do
      get 'assign'
      put 'user/:user_id', :action => "assign_user"
      put 'user/:user_id/leader', :action => "make_leader"      
      delete 'user/:user_id', :action => "unassign_user"
#      put 'assign_user/:id', :action => "testbeds#assign_user"
#      delete 'unassign_user/:id', :action => "testbeds#unassign_user"
    end
  end
  
  scope :module => "library" do
    resources :library, :only => [:index]
    resources :sys_images    
    resources :eds
  end
  
  resources :testbeds
  
  scope :module => "admin", :as => "admin" do
    resources :admin, :path => "admin", :only => [:index]
    devise_for :users , :path => "admin/users", :controllers => { :registrations => "admin/registrations" }    
    resources :users, :path => "admin/users", :only => [:index, :show, :destroy] do
      put '/activate', :action => "activate"
    end    
    resources :sys_images, :path => "admin/sys_images"  
    resources :testbeds, :path => "admin/testbeds"  do
      get '/nodes/:node_id/info', :action => "node_info", :as => "info", :on => :member
      put '/nodes/:node_id/toggle', :action => "node_toggle", :as => "toggle", :on => :member
    end
  end
 
  resources :experiments do
    get 'prepare', :action => 'prepare', :on => :member
    get 'start', :action => 'start', :on => :member
    get 'stop', :action => 'stop', :on => :member
    get 'stat', :action => 'stat', :on => :member
  end
  
  match 'javascripts/application.js' => 'pages#application'
  match 'stylesheets/custom.css' => 'pages#custom'
  
  root :to => "pages#index"
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
