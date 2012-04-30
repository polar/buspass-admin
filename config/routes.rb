BuspassAdmin::Application.routes.draw do

  root :to => "masters#index"

  mount CantangoEditor::Engine => "/cantango_editor"

  devise_for :admins,
             :controllers => {
                 :registrations => "mydevise/registrations",
                 :sessions      => "mydevise/sessions"
             }

  resources :admins

  devise_for :muni_admins,
             :controllers => {
                :registrations => "masters/mydevise/registrations",
                :sessions      => "masters/mydevise/sessions"
             }

  devise_for :users,
             :controllers => {
                 :registrations => "deployments/mydevise/registrations",
                 :sessions      => "deployments/mydevise/sessions"
             }

  # For some bullshit with devise
  resources :muni_admins, :controller => "masters/muni_admins"
  resources :users, :controller => "deployments/users"

  resources :deployments do
    member do
      get :api
    end

    resource :run, :controller => "deployments/run" do
      get :api
      get :map
      post :start
      post :stop
      get :partial_status
      post :deactivate
    end

    resource :webmap, :controller => "deployments/webmap" do
      member do
        get :route
        get :journey
        get :route_journeys
        get :routedef
        get :curloc
      end
    end
  end

  resources :testaments do
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

    resources :muni_admins, :controller => "masters/muni_admins" do
      member do
        post :destroy_confirm
      end
    end
    resources :users, :controller => "masters/users" do
      member do
        post :destroy_confirm
      end
    end

    member do
      get :deployment
      get :testament
    end

    resource :home, :controller => "masters/home" do
      member do
      end
    end

    resources :municipalities, :controller => "masters/municipalities" do
      member do
        get :check
        get :map
        get :api
        post :deploy
        post :testit
      end

      resource :webmap,            :controller => "masters/municipalities/webmap" do
        member do
          get :route
          get :journey
          get :route_journeys
          get :routedef
          get :curloc
        end
      end
      resource :simulate, :controller => "masters/municipalities/simulate" do
        get :api
        get :map
        post :start
        post :stop
        get :partial_status
        resource :webmap,            :controller => "masters/municipalities/simulate/webmap" do
          member do
            get :route
            get :journey
            get :route_journeys
            get :routedef
            get :curloc
          end
        end
      end

      resources :networks, :controller => "masters/municipalities/networks" do
        member do
          post :move
          put :moveto
        end

        resources :services,         :controller => "masters/municipalities/networks/services"
        resources :routes,           :controller => "masters/municipalities/networks/routes"  do
          member do
            get :map
            get :api
          end
          resource :webmap,          :controller => "masters/municipalities/networks/routes/webmap" do
            member do
              get :route
              get :journey
              get :route_journeys
              get :routedef
              get :curloc
            end
          end
        end
        resources :vehicle_journeys, :controller => "masters/municipalities/networks/vehicle_journeys" do
          member do
            get :map
            get :api
          end
          resource :webmap,          :controller => "masters/municipalities/networks/vehicle_journeys/webmap" do
            member do
              get :route
              get :route_journeys
              get :routedef
              get :curloc
            end
          end
        end
        resource :plan,              :controller => "masters/municipalities/networks/plan" do
          member do
            get :display
            get :upload
            get :partial_status
            get :file
          end
        end
        resource :webmap,            :controller => "masters/municipalities/networks/webmap" do
          member do
            get :api
            get :route
            get :route_journeys
            get :routedef
            get :curloc
          end
        end

      end
      resource :plan do
        resource :home,
                 :controller => "masters/municipalities/networks/plan/home",
                 :only => [:edit, :show, :update],
                 :as => "home"

        resources :networks,
                  :controller => "masters/municipalities/plan/networks",
                  :as => "networks" do
          resources :services,
                    :controller => "masters/municipalities/plan/services",
                    :as => "services"
        end
      end

    end
  end
      scope "plan" do
        resource :home,
                 :controller => "masters/plan/home",
                 :only => [:edit, :show, :update],
                 :as => "plan_home"

        resources :networks,
                  :controller => "masters/plan/networks",
                  :as => "plan_networks" do
          resources :services,
                    :controller => "masters/plan/services",
                    :as => "services"
        end

        scope ":network" do
          resource :networkplan,
                    :controller => "masters/plan/plan",
                    :as => "plan_networkplan",
                    :except => [:index] do
            member do
              get :display
              get :upload
              get :partial_status
              get :file
            end
          end

          resources :routes,
                    :controller => "masters/plan/routes",
                    :as => "plan_routes"

          resources :services,
                    :controller => "masters/plan/services",
                    :as => "plan_services"

          scope ":route" do
            resources :services,
                      :controller => "masters/plan/routeservices",
                      :as => "plan_routeservices"
          end
        end
      end

      scope "ops" do
          resource :home,
                   :controller => "masters/ops/home",
                   :only => [:edit, :show, :update],
                   :as => "ops_home"
      end

      scope "cust" do
          resource :home,
                   :controller => "masters/ops/home",
                   :only => [:edit, :show, :update],
                   :as => "cust_home"
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
end
