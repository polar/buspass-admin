module PageUtils

  #
  # This method is called from the Controller that creates the Master.
  # It creates the master's administration pages, by copying the
  # "busme-admin-template" site elements and configuring them appropriately.
  #
  def create_master_admin_site(master)

    from_site = Cms::Site.find_by_identifier("busme-admin-template")

    site = master.admin_site = Cms::Site.create!(
        :path       => "admin",
        :identifier => "#{master.slug}-admin",
        :label      => "#{master.name} Administration Pages",
        :hostname   => "#{master.slug}.busme.us",
        :master     => master
    )

    copy_layouts(site, from_site)
    seed_master_admin_pages_snippets(site, from_site)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  # Site must have master assigned.
  def seed_master_admin_pages_snippets(site, from_site)
    master    = site.master
    from_root = from_site.pages.root

    new_root        = copy_page(site, nil, from_root, true)
    new_root.label  = "#{master.name} Information"
    new_root.master = master

    new_root.save!

    from_site.snippets.order(:position).all.each do |snippet|
      new_snippet = copy_snippet(site, snippet)

      new_snippet.master = site.master

      new_snippet.save!
    end
  end

  # Called from Controller creating a Master.
  def create_master_main_site(master)

    from_site = Cms::Site.find_by_identifier("busme-main-template")

    site = master.main_site = Cms::Site.create!(
        :path       => "",
        :identifier => "#{master.slug}-main",
        :label      => "#{master.name} Active Deployment Pages",
        :hostname   => "#{master.slug}.busme.us",
        :master     => master
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
  def seed_master_main_pages_snippets(site, from_site)
    master = site.master
    from_root = from_site.pages.root

    new_root        = copy_page(site, nil, from_root, true)
    new_root.label  = "#{master.name} Front Page"
    new_root.master = master
    new_root.save!

    from_site.snippets.order(:position).all.each do |snippet|
      new_snippet = copy_snippet(site, snippet)
      new_snippet.master = site.master
      new_snippet.save!
    end
  end

  def create_master_deployment_page(master, muni)
    site = Cms::Site.find_by_identifier("#{master.slug}-admin")

    parent_page = site.pages.find_by_full_path("/deployments")
    template    = site.pages.find_by_full_path("/deployment-template")

    new_page              = copy_page(site, parent_page, template, false)
    new_page.slug         = "#{muni.slug}"
    new_page.label        = "#{muni.name}"
    new_page.master       = master
    new_page.municipality = muni
    new_page.save!

    # Customer may have added other pages to the template.
    # We'll copy those.
    non_descend = ["simulate", "edit", "new-network", "networks"]
    template.children.order(:position).all.each do |child|
      page = copy_page(site, new_page, child, !non_descend.include?(child.slug))
      page.master = master
      page.municipality = muni
      page.save!
    end
    return new_page
  rescue => boom
    Rails.logger.detailed_error(boom)
    new_page.destroy if new_page && new_page.persisted?
    raise boom
  end
  # Called from Controller creating a Master. We only copy the
  # network-template. All pages lower than the network level, i.e.
  # routes, services, and journeys will be gotten via the Master's
  # deployment-template directly.
  def create_master_deployment_network_page(master, muni, network)

    site = Cms::Site.find_by_identifier("#{master.slug}-admin")

    parent_page = site.pages.find_by_full_path("/deployments/#{muni.slug}/networks")
    template    = site.pages.find_by_full_path("/deployment-template/networks/network-template")

    new_page              = copy_page(site, parent_page, template)
    new_page.slug         = "#{network.slug}"
    new_page.label        = "#{network.name}"
    new_page.master       = master
    new_page.municipality = muni
    new_page.network      = network
    new_page.save!
    return new_page
  rescue => boom
    Rails.logger.detailed_error(boom)
    new_page.destroy if new_page && new_page.persisted?
    raise boom
  end

  def copy_page(site, parent, page, recursive = true)
    newp = site.pages.create!(
        :slug              => page.slug,
        :label             => page.label,
        :layout            => site.layouts.find_by_identifier(page.layout.identifier),
        :parent            => parent,
        :master            => site.master,
        :target_page       => page.target_page,
        :is_published      => page.is_published,
        :is_protected      => page.is_protected,
        :controller_path   => page.controller_path,
        :blocks_attributes => page.blocks_attributes
    )
    if recursive
      page.children.order(:position).all.each do |ch|
        copy_page(site, newp, ch, true)
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