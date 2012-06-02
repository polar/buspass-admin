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

    layout = site.layouts.create!(:identifier => "default",
                                  :app_layout => "masters/normal-layout",
                                  :content    => "{{ cms:page:content }}")

    root = site.pages.create!(:slug              => "main",
                              :label             => "#{master.name} Information",
                              :layout            => layout,
                              :master            => master,
                              :blocks_attributes => [{
                                                         :identifier => "content",
                                                         :content    => "{{ cms:bus:master-info }}"
                                                     }])

    newdep = site.pages.create!(:slug              => "new-deployment",
                                :label             => "#{master.name} New Deployment",
                                :layout            => layout,
                                :parent            => root,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:new-deployment }}"
                                                       }])
    create_master_admin_templates(master, site, layout, root)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  def create_master_admin_templates(master, site, layout, root)

    deptmp = site.pages.create!(:slug              => "deployments-template",
                                :label             => "#{master.name} Deployments Template",
                                :layout            => layout,
                                :parent            => root,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployments }}"
                                                       }])

    templa = site.pages.create!(:slug              => "deployment-template",
                                :label             => "#{master.name} Deployment Template",
                                :layout            => layout,
                                :parent            => deptmp,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployment }}"
                                                       }])

    netnew = site.pages.create!(:slug              => "new-network-template",
                                :label             => "#{master.name} New Network Template",
                                :layout            => layout,
                                :parent            => templa,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployment:new-network }}"
                                                       }])

    netedt = site.pages.create!(:slug              => "edit-network-template",
                                :label             => "#{master.name} Edit Network Template",
                                :layout            => layout,
                                :parent            => templa,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployment:edit-network }}"
                                                       }])

    netmov = site.pages.create!(:slug              => "move-network-template",
                                :label             => "#{master.name} Move Network Template",
                                :layout            => layout,
                                :parent            => templa,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployment:move-network }}"
                                                       }])

    nettmp = site.pages.create!(:slug              => "network-template",
                                :label             => "#{master.name} Network Template",
                                :layout            => layout,
                                :parent            => templa,
                                :master            => master,
                                :blocks_attributes => [{
                                                           :identifier => "content",
                                                           :content    => "{{ cms:bus:deployment:network }}"
                                                       }])

    netrtes = site.pages.create!(:slug              => "routes-template",
                                 :label             => "#{master.name} Network Routes Template",
                                 :layout            => layout,
                                 :parent            => nettmp,
                                 :master            => master,
                                 :blocks_attributes => [{
                                                            :identifier => "content",
                                                            :content    => "{{ cms:bus:deployment:network:routes }}"
                                                        }])

    netsrvs = site.pages.create!(:slug              => "services-template",
                                 :label             => "#{master.name} Network Services Template",
                                 :layout            => layout,
                                 :parent            => nettmp,
                                 :master            => master,
                                 :blocks_attributes => [{
                                                            :identifier => "content",
                                                            :content    => "{{ cms:bus:deployment:network:services }}"
                                                        }])

    netjourneys = site.pages.create!(:slug              => "journeys-template",
                                 :label             => "#{master.name} Network Journeys Template",
                                 :layout            => layout,
                                 :parent            => nettmp,
                                 :master            => master,
                                 :blocks_attributes => [{
                                                            :identifier => "content",
                                                            :content    => "{{ cms:bus:deployment:network:journeys }}"
                                                        }])

    netjmap = site.pages.create!(:slug              => "map-journeys-template",
                                 :label             => "#{master.name} Network Journeys Map Template",
                                 :layout            => layout,
                                 :parent            => netjourneys,
                                 :master            => master,
                                 :blocks_attributes => [{
                                                            :identifier => "content",
                                                            :content    => "{{ cms:bus:deployment:network:journeys:map }}"
                                                        }])

    netplan = site.pages.create!(:slug              => "plan-network-template",
                                 :label             => "#{master.name} Network Plan Template",
                                 :layout            => layout,
                                 :parent            => nettmp,
                                 :master            => master,
                                 :blocks_attributes => [{
                                                            :identifier => "content",
                                                            :content    => "{{ cms:bus:deployment:network:plan }}"
                                                        }])

    deps = site.pages.create!(:slug              => "deployments",
                               :label             => "#{master.name} Deployments",
                               :layout            => layout,
                               :parent            => root,
                               :master            => master,
                               :blocks_attributes => [{
                                                          :identifier => "content",
                                                          :content    => "{{ cms:bus:deployments }}"
                                                      }])

    adep = site.pages.create!(:slug              => "active-deployment",
                               :label             => "#{master.name} Active Deployment",
                               :layout            => layout,
                               :parent            => root,
                               :master            => master,
                               :blocks_attributes => [{
                                                          :identifier => "content",
                                                          :content    => "{{ cms:bus:active-deployment }}"
                                                      }])

    tdep = site.pages.create!(:slug              => "test-deployment",
                               :label             => "#{master.name} Test Deployment",
                               :layout            => layout,
                               :parent            => root,
                               :master            => master,
                               :blocks_attributes => [{
                                                          :identifier => "content",
                                                          :content    => "{{ cms:bus:test-deployment }}"
                                                      }])
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  # Called from Controller creating Municipality
  def create_deployment_page(master, muni, parent_page = nil, layout = nil)
    site = master.admin_site

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/deployment-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "#{muni.slug}",
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

  def create_deployment_edit_page(site, muni, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:edit }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/edit-deployment-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "edit",
                              :label             => "Deployment #{muni.name} Edit Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_map_page(site, muni, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:map }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/map-deployment-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "map",
                              :label             => "Deployment #{muni.name} Map Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_simulate_page(site, muni, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:simulate }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/simulate-deployment-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "simulate",
                              :label             => "Deployment #{muni.name} Simulate Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_networks_page(site, muni, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:networks }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/networks-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "networks",
                              :label             => "#{muni.name} Networks Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_new_page(site, muni, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:new-network }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/new-network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "new-network",
                              :label             => "#{muni.name} New Network Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  # Called from Controller creating a network.
  def create_deployment_network_page(master, muni, network, parent_page = nil, layout = nil)
    site = master.admin_site

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "#{network.slug}",
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

  def create_deployment_network_edit_page(site, muni, network, parent_page = nil, layout = nil)
    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:edit-network }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/edit-network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "edit",
                              :label             => "#{muni.name} Edit Network Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_move_page(site, muni, network, parent_page = nil, layout = nil)
    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:move-network }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/move-network-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "move",
                              :label             => "#{muni.name} Move Network Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :blocks_attributes => blocks_attributes)
    return page
  end


  def create_deployment_network_plan_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:plan }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/plan-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "plan",
                              :label             => "#{muni.name} Network #{network.name} Plan Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_plan_upload_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:plan:upload }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/plan-template/upload-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}/plan")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "upload",
                              :label             => "#{muni.name} Network #{network.name} Upload Plan Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_routes_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:routes }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/routes-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "routes",
                              :label             => "#{muni.name} Network #{network.name} Routes Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_services_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:services }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/services-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "services",
                              :label             => "#{muni.name} Network #{network.name} Services Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_journeys_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:journeys }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/journeys-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "journeys",
                              :label             => "#{muni.name} Network #{network.name} Journeys Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

  def create_deployment_network_journeys_map_page(site, muni, network, parent_page = nil, layout = nil)

    blocks_attributes =  [{
                              :identifier => "content",
                              :content    => "{{ cms:bus:deployment:network:journeys:map }}"
                          }]

    template_page = site.pages.find_by_full_path("/deployment-template/network-template/map-journeys-template")

    if template_page
      blocks_attributes = template_page.blocks_attributes
      layout = template_page.layout
    end

    parent_page ||= site.pages.find_by_full_path("/deployments/#{muni.slug}/networks/#{network.slug}")
    layout      ||= site.layouts.find_by_identifier("default")

    page = site.pages.create!(:slug              => "map-journeys",
                              :label             => "#{muni.name} Network #{network.name} Journeys Map Page",
                              :layout            => layout,
                              :parent            => parent_page,
                              :master            => site.master,
                              :municipality      => muni,
                              :network           => network,
                              :blocks_attributes => blocks_attributes)
    return page
  end

end