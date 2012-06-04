module PageUtils

  # Called from Controller creating Master.
  def create_master_admin_site(master)

    site = master.admin_site = Cms::Site.create!(
        :path       => "admin",
        :identifier => "#{master.slug}-admin",
        :label      => "#{master.name} Administration Pages",
        :hostname   => "#{master.slug}.busme.us",
        :master     => master
    )

    layout = site.layouts.create!(
        :identifier => "default",
        :app_layout => "masters/normal-layout",
        :content    => "{{ cms:page:content }}")

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "masters/map-layout",
        :content    => "{{ cms:page:content }}")

    root = site.pages.create!(
        :slug              => "main",
        :label             => "#{master.name} Information",
        :layout            => layout,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:master }}"
                               }])

    create_master_admin_templates(master, site, layout, root)
    create_edit_info_page(site)
    create_new_deployment_page(site)
    create_active_deployment_page(site)
    create_active_testament_page(site)
    create_deployments_page(site)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  def create_master_admin_templates(master, site, layout, root)

    deployment_template = site.pages.create!(
        :slug              => "deployment-template",
        :label             => "#{master.name} Deployment Template",
        :layout            => layout,
        :parent            => root,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment }}"
                               }])

    new_network_template = site.pages.create!(
        :slug              => "new-network-template",
        :label             => "#{master.name} New Network Template",
        :layout            => layout,
        :parent            => deployment_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:networks:new }}"
                               }])

    networks_template = site.pages.create!(
        :slug              => "networks-template",
        :label             => "#{master.name} Networks Template",
        :layout            => layout,
        :parent            => deployment_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:networks }}"
                               }])

    network_template = site.pages.create!(
        :slug              => "network-template",
        :label             => "#{master.name} Network Template",
        :layout            => layout,
        :parent            => networks_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network }}"
                               }])

    edit_network_template = site.pages.create!(
        :slug              => "edit-template",
        :label             => "#{master.name} Edit Network Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:edit }}"
                               }])

    move_network_template = site.pages.create!(
        :slug              => "move-template",
        :label             => "#{master.name} Move Network Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:move }}"
                               }])

    routes_template = site.pages.create!(
        :slug              => "routes-template",
        :label             => "#{master.name} Network Routes Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:routes }}"
                               }])

    route_template = site.pages.create!(
        :slug              => "route-template",
        :label             => "#{master.name} Network Route Template",
        :layout            => layout,
        :parent            => routes_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:route }}"
                               }])

    map_route_template = site.pages.create!(
        :slug              => "map-template",
        :label             => "#{master.name} Network Route Map Template",
        :layout            => layout,
        :parent            => route_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:route:map }}"
                               }])

    services_template = site.pages.create!(
        :slug              => "services-template",
        :label             => "#{master.name} Network Services Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:services }}"
                               }])

    service_template = site.pages.create!(
        :slug              => "service-template",
        :label             => "#{master.name} Network Service Template",
        :layout            => layout,
        :parent            => services_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:service }}"
                               }])

    journeys_template = site.pages.create!(
        :slug              => "journeys-template",
        :label             => "#{master.name} Network Journeys Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:journeys }}"
                               }])

    journey_template = site.pages.create!(
        :slug              => "journey-template",
        :label             => "#{master.name} Network Journey Template",
        :layout            => layout,
        :parent            => journeys_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:journey }}"
                               }])

    map_journey_template = site.pages.create!(
        :slug              => "map-template",
        :label             => "#{master.name} Network Journeys Map Template",
        :layout            => layout,
        :parent            => journey_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:journey:map }}"
                               }])

    plan_network_template = site.pages.create!(
        :slug              => "plan-template",
        :label             => "#{master.name} Network Plan Template",
        :layout            => layout,
        :parent            => network_template,
        :master            => master,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network:plan }}"
                               }])

    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  def create_edit_info_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/edit")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:master:edit }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("default")

    deps = site.pages.create!(
        :slug              => "edit",
        :label             => "#{master.name} Edit Information",
        :layout            => layout,
        :parent            => parent_page,
        :blocks_attributes => blocks_attributes)
  end

  def create_new_deployment_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/new-deployment")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployments:new }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("default")

    deps = site.pages.create!(
        :slug              => "new-deployment",
        :label             => "#{master.name} New Deployment",
        :layout            => layout,
        :parent            => parent_page,
        :blocks_attributes => blocks_attributes)
  end

  def create_deployments_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/deployments")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployments }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("default")

    deps = site.pages.create!(
        :slug              => "deployments",
        :label             => "#{master.name} Deployments",
        :layout            => layout,
        :parent            => parent_page,
        :master            => master,
        :blocks_attributes => blocks_attributes)
  end

  def create_active_deployment_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/active-deployment")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("default")

    deps = site.pages.create!(
        :slug              => "active-deployment",
        :label             => "#{master.name} Active Deployment",
        :layout            => layout,
        :parent            => parent_page,
        :master            => master,
        :blocks_attributes => blocks_attributes)
  end

  def create_active_testament_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/active-testament")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:active-testament }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("default")

    deps = site.pages.create!(
        :slug              => "active-testament",
        :label             => "#{master.name} Active Testament",
        :layout            => layout,
        :parent            => parent_page,
        :master            => master,
        :blocks_attributes => blocks_attributes)
  end

  # Called from Controller creating Municipality
  def create_deployment_page(master, muni, layout = nil, parent_page = nil)

    site = master.admin_site

    if parent_page.nil?
      create_deployments_page(site)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "#{muni.slug}",
        :label             => "Deployment #{muni.name} Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)

    create_deployment_edit_page(site, muni)
    create_deployment_map_page(site, muni)
    create_deployment_simulate_page(site, muni)
    create_deployment_networks_page(site, muni)
    create_deployment_network_new_page(site, muni)

    return page
  end

  def create_deployment_edit_page(site, muni, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_page(site.master, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/edit")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:edit }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/edit-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "edit",
        :label             => "Deployment #{muni.name} Edit Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_map_page(site, muni, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_page(site.master, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/map")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:map }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/map-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    page = site.pages.create!(
        :slug              => "map",
        :label             => "Deployment #{muni.name} Map Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_simulate_page(site, muni, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_page(site.master, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/simulate")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:simulate }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/simulate-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    page = site.pages.create!(
        :slug              => "simulate",
        :label             => "Deployment #{muni.name} Simulate Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_networks_page(site, muni, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_page(site.master, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:networks }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/networks-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "networks",
        :label             => "#{muni.name} Networks Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_new_page(site, muni, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_page(site.master, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/new")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:networks:new }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/new-network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "new-network",
        :label             => "#{muni.name} New Network Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  # Called from Controller creating a network.
  def create_deployment_network_page(master, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_networks_page(site, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    end

    site = master.admin_site

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/networks-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "#{network.slug}",
        :label             => "#{muni.name} Network #{network.name} Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)

    create_deployment_network_edit_page(site, muni, network)
    create_deployment_network_move_page(site, muni, network)
    create_deployment_network_plan_page(site, muni, network)
    create_deployment_network_plan_upload_page(stie, muni, network)
    create_deployment_network_routes_page(site, muni, network)
    create_deployment_network_services_page(site, muni, network)
    create_deployment_network_journeys_page(site, muni, network)
    create_deployment_network_journeys_map_page(site, muni, network)
    return page
  end

  def create_deployment_network_edit_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/edit")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:edit }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/edit-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "edit",
        :label             => "#{muni.name} Edit Network Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_move_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/move")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:move }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/move-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "move",
        :label             => "#{muni.name} Move Network Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_plan_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/plan")
    end


    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:plan }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/plan-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "plan",
        :label             => "#{muni.name} Network #{network.name} Plan Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_plan_upload_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_plan_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/plan/upload")
    end


    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:plan:upload }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/plan-template/upload-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/plan")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "upload",
        :label             => "#{muni.name} Network #{network.name} Upload Plan Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_routes_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/routes")
    end


    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:routes }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/routes-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "routes",
        :label             => "#{muni.name} Network #{network.name} Routes Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_route_page(site, muni, network, route, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_routes_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/routes/#{route.slug}")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:route }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/route-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/routes")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => route.slug,
        :label             => "#{muni.name} Network #{network.name} Route #{route.name} Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :route             => route,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_route_map_page(site, muni, network, route, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_route_page(site, muni, network, route)
      return if site.pages.find_by_full_path("deployments/#{muni.slug}/networks/#{network.slug}/routes/#{route.slug}/map")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:route:map }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/route-template/map-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/routes/#{route.slug}")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    page = site.pages.create!(
        :slug              => "map",
        :label             => "#{muni.name} Network #{network.name} Route #{route.name} Map Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :route             => route,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_services_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/services")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:services }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/services-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "services",
        :label             => "#{muni.name} Network #{network.name} Services Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_service_page(site, muni, network, service, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_services_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/services/#{service.slug}")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:service }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/service-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/services")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => service.slug,
        :label             => "#{muni.name} Network #{network.name} Service #{service.name} Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :service           => service,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_journeys_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site, muni, network)
      return if site.pages.find_by_full_path("deployments/#{muni.slug}/networks/#{network.slug}/journeys")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:journeys }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/journeys-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => "journeys",
        :label             => "#{muni.name} Network #{network.name} Journeys Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_vehicle_journey_page(site, muni, network, journey, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_journeys_page(site, muni, network)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/journeys/#{journey.slug}")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:journey }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/journey-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/journeys")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(
        :slug              => journey.slug,
        :label             => "#{muni.name} Network #{network.name} Journey #{journey.name} Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :vehicle_journey   => journey,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_journey_map_page(site, muni, network, journey, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_journey_page(site, muni, network, journey)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/journeys/#{journey.slug}/map")
    end

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network:journey:map }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/journey-template/map-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/journeys/#{journey.slug}")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    page = site.pages.create!(
        :slug              => "map",
        :label             => "#{muni.name} Network #{network.name} Journey #{journey.name} Map Page",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :vehicle_journey   => journey,
        :blocks_attributes => blocks_attributes)
    return page
  end

end