module PageUtils

  #
  # This method creates the main template site. This is the site
  # that will be copied to for the Administration Pages of a new Master.
  #
  def ensure_admin_site_template
    site = Cms::Site.find_by_identifier("busme-admin-template")

    if site.nil?
      site = Cms::Site.create!(
          :path       => "busme-admin-template",
          :identifier => "busme-admin-template",
          :label      => "Master Administration Pages Template",
          :hostname   => "busme.us"
      )

      layout = site.layouts.create!(
          :identifier => "default",
          :app_layout => "application",
          :content    => "{{ cms:page:content:rich_text }}")

      normal_layout = site.layouts.create!(
          :identifier => "master-normal-layout",
          :app_layout => "masters/normal-layout",
          :content    => "{{ cms:page:content:rich_text }}")

      map_layout = site.layouts.create!(
          :identifier => "master-map-layout",
          :app_layout => "masters/map-layout",
          :content    => "{{ cms:page:content:rich_text }}")

      root = site.pages.create!(
          :slug              => "top",
          :label             => "Front Administration Page",
          :layout            => normal_layout,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Welcome to Busme Site Administration for your municipality. Please follow links on left."
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:main }}"
                                 }
                                 ])

      seed_main_admin_templates(site, normal_layout, map_layout, root)
      create_edit_info_page(site)
      create_new_deployment_page(site)
      create_active_deployment_page(site)
      create_active_testament_page(site)
      create_deployments_page(site)
    end
    return site
  end

  #
  # This method creates the master's main site template. This is the site
  # that will be copied to for the Main Pages of a new Master. It gets done
  # once. If you change and save as fixtures, it should be reloaded from there.
  #
  def ensure_main_site_template
    site = Cms::Site.find_by_identifier("busme-main-template")

    if site.nil?
      site = Cms::Site.create!(
          :path       => "busme-main-template",
          :identifier => "busme-main-template",
          :label      => "Master Main Pages Template",
          :hostname   => "busme.us"
      )

      layout = site.layouts.create!(
          :identifier => "default",
          :app_layout => "application",
          :content    => "{{ cms:page:content:rich_text }}")

      normal_layout = site.layouts.create!(
          :identifier => "master-normal-layout",
          :app_layout => "masters/normal-layout",
          :content    => "{{ cms:page:content:rich_text }}")

      map_layout = site.layouts.create!(
          :identifier => "master-map-layout",
          :app_layout => "masters/map-layout",
          :content    => "{{ cms:page:content:rich_text }}")

      root = site.pages.create!(
          :slug              => "front-page",
          :label             => "Front Main Page",
          :layout            => map_layout,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:active-deployment }}"
                                 }])
    end
    return site
  end

  #
  # This method is called from the Controller that creates the Master.
  # It creates the master's administration pages, by copying the "busme-template" site
  # elements and configuring them appropriately.
  #
  def create_master_admin_site(master)

    from_site = Cms::Site.find_by_identifier("busme-admin-template")

    site = master.admin_site = Cms::Site.create!(
        :path       => "admin",
        :identifier => "#{master.slug}-admin",
        :label      => "#{master.name} Administration Pages",
        :hostname   => "#{master.slug}.busme.us",
        :master     => master,
    )

    copy_layouts(site, from_site)

    layout = site.layouts.find_by_identifier("normal-layout")

    root = site.pages.create!(
        :slug              => "main",
        :label             => "#{master.name} Information",
        :layout            => layout,
        :master            => master,
        :is_protected      => true,
        :master_path       => "/masters/#{master.id}",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:master }}"
                               }])

    seed_master_admin_pages_snippets(site, from_site)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  # Called from Controller creating Master.
  def create_master_main_site(master)

    from_site = Cms::Site.find_by_identifier("busme-main-template")

    site = master.main_site = Cms::Site.create!(
        :path       => "",
        :identifier => "#{master.slug}-main",
        :label      => "#{master.name} Active Deployment Pages",
        :hostname   => "#{master.slug}.busme.us",
        :master     => master,
    )

    copy_layouts(site, from_site)

    seed_master_main_pages_snippets(site, from_site)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  # Site must have master assigned.
  def seed_master_admin_pages_snippets(site, from_site)

    master = site.master
    root   = site.pages.root

    # The master_path attribute tells cms_content/render_html to redirect through
    # the specified controller, which will then render the content of the page after
    # setting Controller/View instance variables.

    from_site.pages.order(:position).all each do |page|
      new_page = copy_page(site, root, page)
      new_page.master = master
      case page.fullpath
        when "/deployment-template"
          # master_paths not needed.
          # They will be assigned on deployment creation when copied.
        when "/edit"
          new_page.master_path = "/masters/#{master.id}/edit"
        when "/new-deployment"
          new_page.master_path = "/masters/#{master.id}/municipalities/new"
        when "/active-deployment"
          new_page.master_path = "/masters/#{master.id}/active"
        when "/active-testament"
          new_page.master_path = "/masters/#{master.id}/testament"
        when "/deployments"
          new_page.master_path = "/masters/#{master.id}/municipalities"
      end
      new_page.save!
    end

    from_site.snippets.order(:position).all.each do |snippet|
      new_snippet = copy_snippet(site, snippet)
      new_snippet.master = site.master
      new_snippet.save!
    end
  end

  # Site must have master assigned.
  def seed_master_main_pages_snippets(site, from_site)
    master = site.master
    root   = site.pages.root

    from_site.pages.order(:position).all each do |page|
      new_page = copy_page(site, root, page)
      new_page.master = master
      case new_page.fullpath
        when "/active-deployment"
          new_page.master_path = "/masters/#{master.id}/active"
      end
      new_page.save!
    end

    from_site.snippets.order(:position).all.each do |snippet|
      new_snippet = copy_snippet(site, snippet)
      new_snippet.master = site.master
      new_snippet.save!
    end
  end

  def create_admin_templates(site, normal_layout, map_layout, root)
    active_deployment_template = site.pages.create!(
        :slug              => "active-deployment-template",
        :label             => "Active Deployment Template",
        :layout            => map_layout,
        :parent            => root,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:active-deployment }}"
                               }])

    deployment_template = site.pages.create!(
        :slug              => "deployment-template",
        :label             => "Deployment Template",
        :layout            => map_layout,
        :parent            => root,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment }}"
                               }])

    new_network_template = site.pages.create!(
        :slug              => "new-network-template",
        :label             => "New Network Template",
        :layout            => normal_layout,
        :parent            => deployment_template,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:networks:new }}"
                               }])

    networks_template = site.pages.create!(
        :slug              => "networks-template",
        :label             => "Networks Template",
        :layout            => normal_layout,
        :parent            => deployment_template,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:networks }}"
                               }])

    network_template = site.pages.create!(
        :slug              => "network-template",
        :label             => "Network Template",
        :layout            => normal_layout,
        :parent            => networks_template,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployment:network }}"
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    deps = site.pages.create!(
        :slug              => "edit",
        :label             => "Edit Information",
        :layout            => layout,
        :parent            => parent_page,
        :is_protected      => true,
        :master            => master,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    deps = site.pages.create!(
        :slug              => "new-deployment",
        :label             => "New Deployment",
        :layout            => layout,
        :parent            => parent_page,
        :is_protected      => true,
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
                             :content    => "{{ cms:bus:deployments:active }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    deps = site.pages.create!(
        :slug              => "active-deployment",
        :label             => "Active Deployment",
        :layout            => layout,
        :parent            => parent_page,
        :is_protected      => true,
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
                             :content    => "{{ cms:bus:deployments:test }}"
                         }]

    parent_page ||= site.pages.find_by_full_path("/")
    layout      ||= site.layouts.find_by_identifier("map-layout")

    deps = site.pages.create!(
        :slug              => "active-testament",
        :label             => "Active Testament",
        :layout            => layout,
        :parent            => parent_page,
        :is_protected      => true,
        :master            => master,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    deps = site.pages.create!(
        :slug              => "deployments",
        :label             => "Deployments",
        :layout            => layout,
        :parent            => parent_page,
        :is_protected      => true,
        :master            => master,
        :master_path       => "/masters/#{site.master.id}",
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "#{muni.slug}",
        :label             => "#{muni.name}",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "edit",
        :label             => "Edit",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/edit",
        :is_protected      => true,
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
        :label             => "Map",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/map",
        :is_protected      => true,
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
        :label             => "Simulate",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/simulate/map",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "networks",
        :label             => "Networks",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "new-network",
        :label             => "New Network",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/new",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end

  # Called from Controller creating a network.
  def create_deployment_network_page(master, muni, network, layout = nil, parent_page = nil)

    site = master.admin_site

    if parent_page.nil?
      create_deployment_networks_page(site, muni)
      return if site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    end

    site = master.admin_site

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:deployment:network }}"
                         }]

    template_page = site.pages.find_by_full_path("/deployment-template/networks-template/network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout            = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks")
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "#{network.slug}",
        :label             => "#{network.name}",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)

    create_deployment_network_edit_page(site, muni, network)
    create_deployment_network_move_page(site, muni, network)
    create_deployment_network_plan_page(site, muni, network)
    create_deployment_network_plan_upload_page(site, muni, network)
    create_deployment_network_routes_page(site, muni, network)
    create_deployment_network_services_page(site, muni, network)
    create_deployment_network_journeys_page(site, muni, network)
    return page
  end

  def create_deployment_network_edit_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "edit",
        :label             => "Edit",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/edit",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_move_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "move",
        :label             => "Move",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/move",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_plan_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "plan",
        :label             => "Plan",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/plan",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "upload",
        :label             => "Upload",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/plan/upload",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_routes_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "routes",
        :label             => "Routes",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/routes",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => route.slug,
        :label             => "#{route.name}",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :route             => route,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/routes/#{route.id}",
        :is_protected      => true,
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
        :label             => "#{route.name} Map",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :route             => route,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/routes/#{route.id}/map",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_services_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "services",
        :label             => "Services",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/services",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => service.slug,
        :label             => "#{service.name}",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :service           => service,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/services/#{service.id}",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_journeys_page(site, muni, network, layout = nil, parent_page = nil)

    if parent_page.nil?
      create_deployment_network_page(site.master, muni, network)
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => "journeys",
        :label             => "Journeys",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/vehicle_journeys",
        :is_protected      => true,
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
    layout      ||= site.layouts.find_by_identifier("normal-layout")

    page = site.pages.create!(
        :slug              => journey.slug,
        :label             => "#{journey.name}",
        :layout            => layout,
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :vehicle_journey   => journey,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/vehicle_journeys/#{journey.id}",
        :is_protected      => true,
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
        :label             => "Map",
        :parent            => parent_page,
        :master            => site.master,
        :municipality      => muni,
        :network           => network,
        :vehicle_journey   => journey,
        :master_path       => "/masters/#{site.master.id}/municipalities/#{muni.id}/networks/#{network.id}/vehicle_journeys/#{journey.id}/map",
        :is_protected      => true,
        :blocks_attributes => blocks_attributes)
    return page
  end


  def copy_page(site, parent, page, recursive = true)
    newp = site.pages.create!(
        :slug              => page.slug,
        :label             => page.label,
        :layout            => page.layout ? site.layouts.find_by_identifier(page.layout.identifier) : nil,
        :parent            => parent,
        :master            => site.master,
        :target_page       => page.target_page,
        :is_published      => page.is_published,
        :is_protected      => page.is_protected,
        :blocks_attributes => page.blocks_attributes
    )
    if recursive
      page.children.order(:position).all.each do |ch|
        copy_page(site, newp, ch)
      end
    end
    return newp
  end

  def copy_layouts(to_site, from_site)
    from_site.layouts.roots.all.each do |layout|
      copy_layout(to_site, nil, layout)
    end
  end

  def copy_layout(site, parent, layout, recursive = true)
    newl = site.layouts.create!(
        :identifier        => layout.identifier,
        :label             => layout.label,
        :app_layout        => layout.app_layout,
        :parent            => parent,
        :master            => site.master,
        :content           => layout.content,
        :css               => layout.css,
        :js                => layout.js
    )
    if recursive
      layout.children.order(:position).all.each do |ch|
        copy_layout(site, newl, ch)
      end
    end
  end

  def copy_snippet(site, snippet)
    news = site.snippets.create!(
        :label => snippet.label,
        :identifier => snippet.identifier,
        :is_shared => snippet.is_shared,
        :content => snippet.content
    )
  end
end