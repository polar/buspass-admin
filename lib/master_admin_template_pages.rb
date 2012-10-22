module PageUtils
  def self.ensure_master_admin_site_template
    site = Cms::Site.find_by_identifier("busme-admin-template")

    return site unless site.nil?

    site = Cms::Site.create!(   # All info here will be replaced on copy
        :path => "admin",
        :identifier => "busme-admin-template",
        :label => "Master Administration Pages Template",
        :hostname => "busme.us"
    )
    layout_content = "<!--
The layout puts left block of page goes into left side of the layout regardless of where it appears here
-->
{{ cms:layout:left }}

<!--
The page content block shows up here.
You can put what ever you want above or below it.
-->
{{ cms:page:content:rich_text }}

<!--
The Layout bottom puts the bottom block of a page into the bottom
of the layout regardless of where it appears here.
-->
{{ cms:layout:bottom }}"

    layout = site.layouts.create!(
        :identifier => "default",
        :app_layout => "application",
        :content => layout_content)

    normal_layout = site.layouts.create!(
        :identifier => "normal-layout",
        :app_layout => "masters/normal-layout",
        :content => layout_content)

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "masters/map-layout",
        :content => layout_content)

    root = site.pages.create!(
        :slug  => "admin-root", # Must be changed on copy
        :label => "Administration",
        :layout => normal_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "<h1>Welcome to Administration Pages</h1>{{ cms:bus:master }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    help = site.pages.create!(
        :slug => "help",
        :label => "Help",
        :layout => normal_layout,
        :is_protected => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "Help for your Master"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    tools = site.pages.create!(
        :slug => "tools",
        :label => "Tools",
        :layout => map_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/tools",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/tools/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    stoppointsfinder = site.pages.create!(
        :slug              => "journey_path_finder",
        :label             => "Journey Path Finder",
        :parent            => tools,
        :layout            => map_layout,
        :is_protected      => true,
        :controller_path   => "/masters/:master_id/tools/stop_points_finder",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/tools/stop_points_finder/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    pathfinder = site.pages.create!(
        :slug              => "pathfinder",
        :label             => "Timing Link Path Finder",
        :parent            => tools,
        :layout            => map_layout,
        :is_protected      => true,
        :controller_path   => "/masters/:master_id/tools/pathfinder",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/tools/pathfinder/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    edit = site.pages.create!(
        :slug => "edit",
        :label => "Edit",
        :layout => map_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    new_deployment = site.pages.create!(
        :slug => "new-deployment",
        :label => "New Deployment",
        :layout => normal_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/new }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    active_deployment = site.pages.create!(
        :slug => "active-deployment",
        :label => "Active Deployment",
        :layout => normal_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/active",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/active/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    active_testament = site.pages.create!(
        :slug => "active-testament",
        :label => "Active Testament",
        :layout => normal_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/testament",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/testament/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])
    deployments = site.pages.create!(
        :slug => "deployments",
        :label => "Deployments",
        :layout => normal_layout,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:/masters/deployments/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])


    muni_admins = site.pages.create!(
        :slug => "muni_admins",
        :label => "Adminstrators",
        :layout => normal_layout,
        :parent => root,
        :is_protected => true,
        :controller_path => "/masters/:master_id/muni_admins",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/muni_admins/admin }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    users = site.pages.create!(
        :slug => "users",
        :label => "Users",
        :layout => normal_layout,
        :parent => root,
        :is_protected => true,
        :controller_path => "/masters/:master_id/users/admin",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/users/admin }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    pages_admin = site.pages.create!(
        :slug              => "pages",
        :label             => "Pages Admin",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/cms-admin/sites?master_id=:master_id")

    deployment_template = site.pages.create!(
        :slug => "deployment-template",
        :label => "Deployment Template",
        :layout => normal_layout,
        :parent => root,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    deployment_edit =  site.pages.create!(
        :slug => "edit",
        :label => "Edit",
        :layout => normal_layout,
        :parent => deployment_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    deployment_map =  site.pages.create!(
        :slug => "map",
        :label => "Map",
        :layout => map_layout,
        :parent => deployment_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/map",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/map }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    deployment_simulate =  site.pages.create!(
        :slug => "simulate",
        :label => "Simulate",
        :layout => map_layout,
        :parent => deployment_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/simulate",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/simulate/map }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    new_network_template = site.pages.create!(
        :slug => "new-network",
        :label => "New Network",
        :layout => normal_layout,
        :parent => deployment_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/new }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    networks_template = site.pages.create!(
        :slug => "networks",
        :label => "Networks",
        :layout => normal_layout,
        :parent => deployment_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/deployment_nav }}"
                               }])

    network_template = site.pages.create!(
        :slug => "network-template",
        :label => "Network Template",
        :layout => normal_layout,
        :parent => networks_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    edit_network_template = site.pages.create!(
        :slug => "edit",
        :label => "Edit",
        :layout => normal_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    map_network_template = site.pages.create!(
        :slug => "map",
        :label => "Map",
        :layout => map_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/map",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/map }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    routes_template = site.pages.create!(
        :slug => "routes",
        :label => "Routes",
        :layout => normal_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/routes",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/routes/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    route_template = site.pages.create!(
        :slug => "route-template",
        :label => "Network Route Template",
        :layout => normal_layout,
        :parent => routes_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/routes/:route_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/routes/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    map_route_template = site.pages.create!(
        :slug => "map",
        :label => "Map",
        :layout => map_layout,
        :parent => route_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/routes/:route_id/map",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/routes/map }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    services_template = site.pages.create!(
        :slug => "services",
        :label => "Services",
        :layout => normal_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/services",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/services/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    service_template = site.pages.create!(
        :slug => "service-template",
        :label => "Network Service Template",
        :layout => normal_layout,
        :parent => services_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/services/:service_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/services/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    journeys_template = site.pages.create!(
        :slug => "journeys",
        :label => "Journeys",
        :layout => normal_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/vehicle_journeys",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/vehicle_journeys/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    journey_template = site.pages.create!(
        :slug => "journey-template",
        :label => "Network Journey Template",
        :layout => normal_layout,
        :parent => journeys_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/vehicle_journeys/:vehicle_journey_id",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/vehicle_journeys/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    map_journey_template = site.pages.create!(
        :slug => "map",
        :label => "Map",
        :layout => map_layout,
        :parent => journey_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/vehicle_journeys/:vehicle_journey_id/map",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/vehicle_journeys/map }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    plan_network_template = site.pages.create!(
        :slug => "plan",
        :label => "Plan",
        :layout => normal_layout,
        :parent => network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/plan",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/plan/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    upload = site.pages.create!(
        :slug => "upload",
        :label => "Upload",
        :layout => normal_layout,
        :parent => plan_network_template,
        :is_protected => true,
        :controller_path => "/masters/:master_id/deployments/:deployment_id/networks/:network_id/plan/upload",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/deployments/networks/plan/upload }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/network_nav }}"
                               }])

    return site
  end
end