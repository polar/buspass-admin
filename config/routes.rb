BuspassAdmin::Application.routes.draw do

  #root :to => "/"
  #
  match "/auth/:provider/callback" => "sessions#create"
  match "/masters/:master_id/auth/:provider/callback" => "sessions#create"

  match "/masters/:master_id/signout" => "sessions#destroy", :as => :signout

  match "/customers/sign_in" => "sessions#new_customer", :as => :customer_sign_in
  match "/customers/signout" => "sessions#destroy_customer", :as => :customer_signout

  resources :sessions do
    collection do
      get :new_customer
      post :create_customer
      delete :destroy_customer

      get :new_muni_admin
      post :create_muni_admin
      delete :destroy_muni_admin
    end
  end

  resources :customer_authentications
  resources :customer_registrations,
            :only => [ :new, :edit, :create, :update ]

  resources :customers


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

  resources :masters do

    match "sign_in" => "sessions#new_muni_admin", :as => :muni_admin_sign_in
    match "signout" => "sessions#destroy_muni_admin", :as => :muni_admin_signout

    resources :muni_admin_registrations,
              :only => [:new, :edit, :create, :update],
              :controller => "masters/muni_admin_registrations"

    resources :muni_admin_authentications,
              :only => [:create, :destroy],
              :controller => "masters/muni_admin_authentications"

    resource "active", :only => [:show], :controller => "masters/active" do
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
        post :destroy_confirm
      end
      collection do
        get  :new_registration
        get  :edit_registration
        post :create_registration
        put :update_registration
      end
    end

    resources :users, :controller => "masters/users" do
      collection do
        get :admin
      end
      member do
        post :destroy_confirm
      end
    end

    member do
      get :activement
      get :testament
    end

    resource :tools, :controller => "masters/tools" do
      resource :pathfinder, :controller => "masters/tools/pathfinder", :only => [:show]
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

  resource :main, :controller => "main" do
    post :import
    post :export
  end

  root :to =>  "cms_content#render_html", :constraints => { :host => "busme.us" }
  root :to =>  "cms_content#render_html", :constraints => { :host => "localhost" }
  root :to => "masters/active#show"
  match "/transport.php" => "transport#transport"
  match "/busme-admin" => "masters#index"
  match "/cms-admin" => "cms_admin/sites#index"
  match "/:master_id/cms-admin" => "cms_admin/sites#index"
  mount ComfortableMexicanSofa::Engine => "/", :as => :cms
  match "/(*cms_path)/sitemap" => "cms_content#render_sitemap"
  match "/(*cms_path)" => "cms_content#render_html"
end
