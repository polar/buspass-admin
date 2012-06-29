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

    master = site.master
    root   = site.pages.root

    # The master_path attribute tells cms_content/render_html to redirect through
    # the specified controller, which will then render the content of the page after
    # setting Controller/View instance variables.

    from_site.pages.order(:position).all each do |page|
      new_page = copy_page(site, root, page)
      new_page.master = master
      case page.fullpath
        when "/"
          new_page.master_path = "/masters/#{master.id}"
          new_page.label = "#{master.name} Information"
        when "sign-up"
          new_page.master_path = "/masters/mydevise/registrations"
        when "sign-in"
          new_page.paster_path = "/masters/mydevise/sessions/new"
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
        when "/muni_admins"
          new_page.master_path = "/masters/#{master.id}/muni_admins"
        when "/users"
          new_page.master_path = "/masters/#{master.id}/users"
      end
      new_page.save!
    end

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
    root   = site.pages.root

    from_site.pages.order(:position).all each do |page|
      new_page = copy_page(site, root, page)
      new_page.master = master
      case new_page.fullpath
        when "/"
          new_page.master_path = "/masters/#{master.id}/main"
        when "/sign-up"
          new_page.master_path = "/masters/mydevise/registrations"
        when "/sign-in"
          new_page.paster_path = "/masters/mydevise/sessions/new"
        when "/downloads"
          new_page.master_path = "/masters/#{master.id}/downloads"
      end
      new_page.save!
    end

    from_site.snippets.order(:position).all.each do |snippet|
      new_snippet = copy_snippet(site, snippet)
      new_snippet.master = site.master
      new_snippet.save!
    end
  end

  # Called from Controller creating a Master.
  def create_master_deployment_network_page(master, muni, network)

    from_site = Cms::Site.find_by_identifier("#{master.slug}-admin")

    page = from_site.pages.find_by_fullpath("/deployments/#{muni.slug}/networks")

    seed_master_deployment_network_pages(site, page, network)
    return site
  rescue => boom
    Rails.logger.detailed_error(boom)
    site.destroy if site && site.persisted?
    raise boom
  end

  def seed_master_deployment_network_pages(site, parent_page, master, muni, network, page)
    new_page = copy_page(site, parent_page, page, false)
    new_page.master = master
    new_page.municipality = muni
    new_page.network      = network

    page.children.all.each do |child|
      seed_master_deployment_network_pages(site, new_page, master, muni, network, child)
    end

    return new_page
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