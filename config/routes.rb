BuspassAdmin::Application.routes.draw do

  root :to => "municipalities#index"

  mount CantangoEditor::Engine => "/cantango_editor"

  devise_for :admins,
             :controllers => {
                 :registrations => "mydevise/registrations",
                 :sessions      => "mydevise/sessions"
             }

  resources :admins

  resources :municipalities

  scope ":muni" do
      devise_for :muni_admins, :controllers => {
          :registrations => "muni/mydevise/registrations",
          :sessions => "muni/mydevise/sessions" }

      resources :muni_admins, :controller => "muni/muni_admins"
  end

  scope ":muni" do
      root :to => "muni/home#show"

      resource :home,
               :controller => "muni/home",
               :only => [:edit, :show, :update]

      resources :networks,
                :controller => "muni/networks" do
        resources :services,
                  :controller => "muni/networks/services"
        resources :routes,
                  :controller => "muni/networks/routes"
        resources :vehicle_journeys,
                  :controller => "muni/networks/vehicle_journeys"
      end

      scope "plan" do
        resource :home,
                 :controller => "muni/plan/home",
                 :only => [:edit, :show, :update],
                 :as => "plan_home"

        resources :networks,
                  :controller => "muni/plan/networks",
                  :as => "networks"  do
          resources :services,
                    :controller => "muni/plan/services",
                    :as => "services"
        end

        scope ":network" do
          resource :networkplan,
                    :controller => "muni/plan/networkplan",
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
                    :controller => "muni/plan/routes",
                    :as => "plan_routes"

          resources :services,
                    :controller => "muni/plan/services",
                    :as => "plan_services"

          scope ":route" do
            resources :services,
                      :controller => "muni/plan/routeservices",
                      :as => "plan_routeservices"
          end
        end
      end

      scope "ops" do
          resource :home,
                   :controller => "muni/ops/home",
                   :only => [:edit, :show, :update],
                   :as => "ops_home"
      end

      scope "cust" do
          resource :home,
                   :controller => "muni/ops/home",
                   :only => [:edit, :show, :update],
                   :as => "cust_home"
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
end
