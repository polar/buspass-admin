

BuspassAdmin::Application.routes.draw do

  match "/auth/:provider/callback" => "sessions#create"
  match "/auth/failure" => "auth#failure"
  match "/:siteslug/auth/:provider/callback" => "sessions#create", :constraints => { :host => "busme.us" }
  match "/masters/:master_id/auth/:provider/callback" => "sessions#create"

  match "/masters/:master_id/signout" => "sessions#destroy", :as => :signout

  match "/customers/sign_in" => "sessions#new_customer", :as => :customer_sign_in,
        :constraints => { :host => Rails.application.base_host }
  match "/customers/signout" => "sessions#destroy_customer", :as => :customer_signout,
        :constraints => { :host => Rails.application.base_host }

  match "/admin/sign_in" => "sessions#new_muni_admin", :as => :host_master_muni_admin_sign_in,
        :constraints => { :host => /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
  match "/:master_id/admin/sign_in" => "sessions#new_muni_admin", :as => :master_muni_admin_sign_in,
        :constraints => { :host => Rails.application.base_host }
  match "/:master_id/sign_in" => "sessions#new_user", :as => :master_user_sign_in,
        :constraints => { :host => Rails.application.base_host }
  match "/:master_id/mobile_sign_in" => "mobile_sessions#new_user", :as => :master_mobile_user_sign_in,
        :constraints => { :host => Rails.application.base_host }
  match "/:master_id/app_sign_in" => "mobile_sessions#app_sign_in", :as => :master_app_sign_in,
        :constraints => { :host => Rails.application.base_host }
  match "/sign_in" => "sessions#new_user", :as => :host_master_user_sign_in,
        :constraints => { :host => /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
  match "/sign_in" => "sessions#new_customer", :as => :customer_sign_in,
        :constraints => { :host => Rails.application.base_host }



  #match "/:master_id/apis/:version/:action", :controller => "apis#host", :constraints => { :host => Rails.application.base_host }
  #match "/:master_id/:version/:action", :controller => "apis#apis_host", :constraints => { :host => /^apis.#{Rails.application.base_host}$/ }
  #match "/apis/:version/:action", :controller => "apis#master_host", :constraints => { :host => /^[\w\-]+\.#{Rails.application.base_host}$/ }
  #match "/:version/:action", :controller => "apis#apis_master_host", :constraints => { :host => /^apis\.[\w\-]+\.#{Rails.application.base_host}$/ }


  match "/apis/:version" => "apis#show", :as => "show_api",
        :constraints => { :host => Rails.application.base_host }
  match "/apis/:version/:call" => "apis#api_host", :as => "api_host",
        :constraints => { :host => Rails.application.base_host }

  match "/:version/:call" => "apis#apis_master_host", :as => "apis_master_host_apis",
        :constraints => { :host => /^apis\.(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
  match "/apis/:version/:call" => "apis#master_host", :as => "master_host_apis",
        :constraints => { :host => /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
  match "/:master_id/apis/:version/:call" => "apis#host", :as => "host_apis",
        :constraints => { :host => Rails.application.base_host }
  match "/:master_id/:version/:call" => "apis#apis_host", :as => "apis_host_apis",
        :constraints => { :host => "apis.#{Rails.application.base_host}" }

  # This route is for the image links held in pages for use with the Wyswig editor.
  # It redirects paths to the
  match "s3image/(*id)" => "s3_images#show"
  resources :feedbacks
  resources :page_errors

  resources :sessions do
    collection do
      get :new_customer
      post :create_customer
      delete :destroy_customer

      get :new_muni_admin
      post :create_muni_admin
      delete :destroy_muni_admin

      get :new_user
      post :create_user
      delete :destroy_user
    end
  end
  resources :mobile_sessions do
    collection do
      get :new_user
    end
  end

  resource :admin, :only => [:show], :controller => :admin

  resources :customer_authentications, :only => [:destroy]
  resources :customer_registrations,
            :only => [ :new, :edit, :create, :update ]

  resources :customers

  resources :jobs
  resources :workers do
    member do
      post :start
      delete :stop
      delete :remove_jobs
      post :up_limit
      post :down_limit
    end
  end

  namespace :cms_admin, :path => "/cms-admin", :except => :show do
    get '/', :to => 'base#jump'
    resources :sites do
      get :preview, :controller => :preview
      resources :pages do
        get :form_blocks, :on => :member
        get :toggle_branch, :on => :member
        put :reorder, :on => :collection
        resources :revisions, :only => [:index, :show, :revert] do
          put :revert, :on => :member
        end
      end
      resources :files do
        put :reorder, :on => :collection
      end
      resources :layouts do
        put :reorder, :on => :collection
        resources :revisions, :only => [:index, :show, :revert] do
          put :revert, :on => :member
        end
      end
      resources :snippets do
        put :reorder, :on => :collection
        resources :revisions, :only => [:index, :show, :revert] do
          put :revert, :on => :member
        end
      end
      resources :categories
      get 'dialog/:type' => 'dialogs#show', :as => 'dialog'
    end
  end

=begin

  devise_for :customers,
             :controllers => {
                 :registrations => "mydevise/registrations",
                 :sessions      => "mydevise/sessions"
             }

  devise_for :muni_admins,
             :controllers => {
                 :registrations => "masters/muni_admins_devise/registrations",
                 :sessions      => "masters/muni_admins_devise/sessions"
             }

  devise_for :users,
             :controllers => {
                 :registrations => "masters/users_devise/registrations",
                 :sessions      => "masters/users_devise/sessions"
             }

  resources :customers
=end
  resources :passwords

  resources :websites do
    collection do
      get :my_index
      get :admin
    end
    member do
      get :create_confirm
      post :admin_cms
      delete :admin_cms
    end
  end

  resources :activements, :only => :show do
    member do
      get :api
    end

    resource :run, :controller => "activements/run" do
      get :api
      get :map
      post :start
      post :stop
      get :partial_status
      post :deactivate
    end

    resource :webmap, :controller => "activements/webmap" do
      member do
        get :route
        get :journey
        get :route_journeys
        get :routedef
        get :curloc
      end
    end
  end

  resources :testaments, :only => :show do
    member do
      get :api
    end

    resource :run, :controller => "testaments/run" do
      get :api
      get :map
      post :start
      post :stop
      get :partial_status
      post :deactivate
    end

    resource :webmap, :controller => "testaments/webmap" do
      member do
        get :route
        get :journey
        get :route_journeys
        get :routedef
        get :curloc
      end
    end
  end

  resources :masters, :only => [:show, :edit, :update] do

    match "sign_in" => "sessions#new_muni_admin", :as => :muni_admin_sign_in
    match "signout" => "sessions#destroy_muni_admin", :as => :muni_admin_signout
    match "user_sign_in" => "sessions#new_user", :as => :user_sign_in
    match "user_signout" => "sessions#destroy_user", :as => :user_signout

    resources :muni_admin_registrations,
              :only => [:new, :edit, :create, :update],
              :controller => "masters/muni_admin_registrations"

    resources :muni_admin_authentications,
              :only => [:destroy],
              :controller => "masters/muni_admin_authentications"

    resources :user_registrations,
              :only => [:new, :edit, :create, :update],
              :controller => "masters/user_registrations" do
      collection do
        get :new_mobile
        post :create_mobile
      end
      member do
        get :edit_mobile
        put  :update_mobile
      end
    end

    resources :user_authentications,
              :only => [:destroy],
              :controller => "masters/user_authentications"

    resource "sitemap", :controller => "masters/sitemap" do
      member do
        get :admin
        get :main
      end
    end

    namespace :cms_admin, :path => "/cms-admin", :except => :show do
      get '/', :to => 'base#jump'
      resources :sites do
        get :preview, :controller => :preview
        resources :pages do
          get :form_blocks, :on => :member
          get :toggle_branch, :on => :member
          put :reorder, :on => :collection
          resources :revisions, :only => [:index, :show, :revert] do
            put :revert, :on => :member
          end
        end
        resources :files do
          put :reorder, :on => :collection
        end
        resources :layouts do
          put :reorder, :on => :collection
          resources :revisions, :only => [:index, :show, :revert] do
            put :revert, :on => :member
          end
        end
        resources :snippets do
          put :reorder, :on => :collection
          resources :revisions, :only => [:index, :show, :revert] do
            put :revert, :on => :member
          end
        end
        resources :categories
        get 'dialog/:type' => 'dialogs#show', :as => 'dialog'
      end
    end


    resource "admin", :only => [:show], :controller => "masters/admin"

    resources "import_export_sites", :controller => "import_export_sites"

    resources :workers, :controller => "masters/workers" do
      member do
        post :start
        delete :stop
        delete :remove_jobs
        post :up_limit
        post :down_limit
      end
    end

    resource "active", :only => [:show], :controller => "masters/active" do
      member do
        get :api
        get :partial_status
      end
    end

    resource "activement", :only => [:show], :controller => "masters/activement" do
      member do
        get :api
        post :start
        post :stop
        get :partial_status
        post :deactivate
        get :admin
      end
    end

    resource "testament", :only => [:show], :controller => "masters/testament" do
      member do
        get :map
        get :api
        post :start
        post :stop
        get :partial_status
        post :deactivate
      end
    end

    resources :muni_admins, :controller => "masters/muni_admins" do
      member do
        get :destroy_confirm
        delete :destroy_confirmed
      end
      collection do
        get  :new_registration
        get  :edit_registration
        post :create_registration
        put :update_registration
      end
    end

    resources :muni_admin_auth_codes, :only => [:index], :controller => "masters/muni_admin_auth_codes"

    resources :users, :only => [:index, :update, :destroy], :controller => "masters/users"

    member do
      get :activement
      get :testament
    end

    resource :tools, :controller => "masters/tools" do
      resource :stop_points_finder, :controller => "masters/tools/stop_points_finder", :only => [:show] do
        member do
          post :download
        end
      end
    end

    resources :downloads, :controller => "masters/downloads" do
      member do
      end
    end

    resource :home, :controller => "masters/home" do
      member do
      end
    end

    resources :deployments, :controller => "masters/deployments" do
      member do
        get :check
        get :map
        get :api
        post :deploy
        post :testit
      end

      resource :webmap,            :controller => "masters/deployments/webmap" do
        member do
          get :route
          get :journey
          get :route_journeys
          get :routedef
          get :curloc
        end
      end

      resource :simulate, :controller => "masters/deployments/simulate" do
        get :api
        get :map
        post :start
        post :stop
        get :partial_status
        resource :webmap,            :controller => "masters/deployments/simulate/webmap" do
          member do
            get :route
            get :journey
            get :route_journeys
            get :routedef
            get :curloc
          end
        end
      end

      resources :networks, :controller => "masters/deployments/networks" do
        member do
          get :copy
          put :copyto
          get :partial_status
          get :map
          get :api
        end

        resources :services,         :controller => "masters/deployments/networks/services"

        resources :routes,           :controller => "masters/deployments/networks/routes"  do
          member do
            get :map
            get :api
          end

          resource :webmap,          :controller => "masters/deployments/networks/routes/webmap" do
            member do
              get :route
              get :journey
              get :route_journeys
              get :routedef
              get :curloc
            end
          end
        end

        resources :vehicle_journeys, :controller => "masters/deployments/networks/vehicle_journeys" do
          member do
            get :map
            get :api
          end

          resources :journey_pattern_timing_links, :controller => "masters/deployments/networks/vehicle_journeys/journey_pattern_timing_links" do
            member do
              get :kml
              put :update_kml
              post :update_timing_links_1
              post :update_timing_links_2
            end
          end

          resource :webmap,          :controller => "masters/deployments/networks/vehicle_journeys/webmap" do
            member do
              get :route
              get :route_journeys
              get :routedef
              get :curloc
            end
          end
        end

        resource :plan,              :controller => "masters/deployments/networks/plan" do
          member do
            get :display
            get :upload
            get :partial_status
            post :abort
            post :download
            get :file
          end
        end

        resource :webmap,            :controller => "masters/deployments/networks/webmap" do
          member do
            get :route
            get :route_journeys
            get :routedef
            get :curloc
          end
        end

      end
    end
  end

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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'

  resources "import_export_sites", :controller => "import_export_sites" do
    member do
      put :import
      post :export
    end
  end

  root :to => "cms_content#render_html"

  match "/transport.php" => "transport#transport"

  match "/busme-admin" => "masters#index"
  match "/:master_id/cms-admin" => "cms_admin/sites#index"
  match "/(*cms_path)/sitemap" => "cms_content#render_sitemap"

  match "/(*cms_path)" => "cms_content#master_host_render_cms", :as => "master_host_remder_cms",
        :constraints => { :host => /^(?<master_id>[\w\-]+)\.#{Rails.application.base_host}$/ }
  match "/:master_id/(*cms_path)" => "cms_content#master_render_cms", :as => "master_render_cms",
        :constraints => { :host => Rails.application.base_host }
  match "/(*cms_path)" => "cms_content#render_html"
end
