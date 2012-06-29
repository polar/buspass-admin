module PageUtils
  def ensure_master_admin_site_template
    site = Cms::Site.find_by_identifier("busme-admin-template")

    if site.nil?

      site = Cms::Site.create!(
          :path       => "main",
          :identifier => "main",
          :label      => "Master Administration Pages Template",
          :hostname   => "busme.us"
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
                                     :content    => "Welcome to the Administration of your Municipality"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      help = site.pages.create!(
          :slug              => "help",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Help for Admin"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      edit = site.pages.create!(
          :slug              => "edit",
          :label             => "Edit Info",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:municipalities:edit }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      new_deployment = site.pages.create!(
          :slug              => "new-deployment",
          :label             => "New Deployment",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:municipalities:new }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      active_deployment = site.pages.create!(
          :slug              => "active-deployment",
          :label             => "Active Deployment",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:municipalities:active }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      active_testament = site.pages.create!(
          :slug              => "active-testament",
          :label             => "Active Testament",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:municipalities:testament }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])

      deployments = site.pages.create!(
          :slug              => "deployments",
          :label             => "Deployments",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:municipalities:index }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content   => "{{ cms:bus:navigation:admin_nav }}"
                                 }])
    end
  end

  def create_edit_info_page(site, layout = nil, parent_page = nil)

    if parent_page.nil?
      return if site.pages.find_by_full_path("/edit")
    end

    master = site.master

    blocks_attributes = [{
                             :identifier => "content",
                             :content    => "{{ cms:bus:master:edit }}"
                         },
                         {
                             :identifier => "left",
                             :content   => "{{ cms:bus:navigation:admin_nav }}"
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
                         },
                         {
                             :identifier => "left",
                             :content   => "{{ cms:bus:navigation:admin_nav }}"
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
                         },
                         {
                             :identifier => "left",
                             :content   => "{{ cms:bus:navigation:admin_nav }}"
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
                         },
                         {
                             :identifier => "left",
                             :content   => "{{ cms:bus:navigation:admin_nav }}"
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
                         },
                         {
                             :identifier => "left",
                             :content   => "{{ cms:bus:navigation:admin_nav }}"
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

end