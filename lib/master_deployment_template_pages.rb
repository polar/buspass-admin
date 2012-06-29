module PageUtils

  def ensure_master_deployment_site_template

    site = Cms::Site.find_by_identifier("busme-deployment-template")

    if site.nil?

      site = Cms::Site.create!(
          :path       => "deployment", # Will be replaced
          :identifier => "busme-deployment-template",
          :label      => "Master Deployment Pages Template", # Will be replaced
          :hostname   => "busme.us" # Will be replaced.
      )

      layout = site.layouts.create!(
          :identifier => "default",
          :app_layout => "application",
          :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

      normal_layout = site.layouts.create!(
          :identifier => "master-normal-layout",
          :app_layout => "masters/normal-layout",
          :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

      map_layout = site.layouts.create!(
          :identifier => "master-map-layout",
          :app_layout => "masters/map-layout",
          :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

      root = site.pages.create!(
          :slug              => "",
          :label             => "Welcome",
          :layout            => normal_layout,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Welcome to the Administration of your Deployment\n{{ cms:bus:deployment }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      help = site.pages.create!(
          :slug              => "help",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Help for Administration of {{ cms:bus:deployment:name }}."
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      deployment = site.pages.create!(
          :slug              => "deployment-template", # Will be replaced by deployment name
          :label             => "Deployment Template", # will be replaced
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      new_network = site.pages.create!(
          :slug              => "new-network",
          :label             => "New Network",
          :layout            => normal_layout,
          :parent            => deployment,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:networks:new }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      networks = site.pages.create!(
          :slug              => "networks",
          :label             => "Networks",
          :layout            => normal_layout,
          :parent            => deployment,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:networks }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      network_template = site.pages.create!(
          :slug              => "network-template", # Will be replace with slug
          :label             => "Network Template", # Will be replaced
          :layout            => normal_layout,
          :parent            => networks_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      edit_network_template = site.pages.create!(
          :slug              => "edit-template",
          :label             => "Edit Network Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:edit }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      move_network_template = site.pages.create!(
          :slug              => "move-template",
          :label             => "Move Network Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:move }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      routes_template = site.pages.create!(
          :slug              => "routes-template",
          :label             => "Network Routes Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:routes }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      route_template = site.pages.create!(
          :slug              => "route-template",
          :label             => "Network Route Template",
          :layout            => normal_layout,
          :parent            => routes_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:route }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      map_route_template = site.pages.create!(
          :slug              => "map-template",
          :label             => "Network Route Map Template",
          :layout            => map_layout,
          :parent            => route_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:route:map }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      services_template = site.pages.create!(
          :slug              => "services-template",
          :label             => "Network Services Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:services }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      service_template = site.pages.create!(
          :slug              => "service-template",
          :label             => "Network Service Template",
          :layout            => normal_layout,
          :parent            => services_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:service }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      journeys_template = site.pages.create!(
          :slug              => "journeys-template",
          :label             => "Network Journeys Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:journeys }}"
                                 }])

      journey_template = site.pages.create!(
          :slug              => "journey-template",
          :label             => "Network Journey Template",
          :layout            => normal_layout,
          :parent            => journeys_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:journey }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      map_journey_template = site.pages.create!(
          :slug              => "map-template",
          :label             => "Network Journey Map Template",
          :layout            => map_layout,
          :parent            => journey_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:journey:map }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      plan_network_template = site.pages.create!(
          :slug              => "plan-template",
          :label             => "Network Plan Template",
          :layout            => normal_layout,
          :parent            => network_template,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:deployment:network:plan }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:deployment_nav }}"
                                 }])

      return site
    end
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end
end
