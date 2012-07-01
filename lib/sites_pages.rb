module PageUtils

  puts "Defining ensure_sites_pages_site"

  def self.ensure_sites_pages_site

    site = Cms::Site.find_by_identifier("busme-main")

    return site unless site.nil?

    site = Cms::Site.create!(
        :path       => "/",
        :identifier => "busme-main",
        :label      => "Sites Pages",
        :hostname   => "busme.us"
    )

    layout = site.layouts.create!(
        :identifier => "default",
        :app_layout => "application",
        :content    => "{{ cms:page:content:rich_text }}")

    normal_layout = site.layouts.create!(
        :identifier => "normal-layout",
        :app_layout => "sites/normal-layout",
        :content    => "{{ cms:bus:page:left:text }}\n{{ cms:page:content:rich_text }}")

    root = site.pages.create!(
        :slug              => "busme-main-root",
        :label             => "Welcome",
        :layout            => normal_layout,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "Welcome to Busme!"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    help = site.pages.create!(
        :slug              => "help",
        :label             => "Help",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => false,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "Help with Busme Site"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    signup = site.pages.create!(
        :slug              => "sign-up",
        :label             => "Sign Up",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/customers/sign_up",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:customers:sign_up }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    signin = site.pages.create!(
        :slug              => "sign-in",
        :label             => "Sign In",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/customers/sign_in",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:customers:sign_in }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])


    index = site.pages.create!(
        :slug              => "all-sites",
        :label             => "All Sites",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/sites/index",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    myindex = site.pages.create!(
        :slug              => "my-sites",
        :label             => "My Sites",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/sites/my_index",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:my_index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    new_site      = site.pages.create!(
        :slug              => "new-site",
        :label             => "New Municipality Site",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/sites/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:new }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    # This page will not be considered in the navigation because the slug ends in template.
    site_template = site.pages.create!(
        :slug              => "site-template",
        :label             => "Will be replaced",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/sites/:site_id/show",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    site_edit_template = site.pages.create!(
        :slug              => "edit",
        :label             => "Will be replaced",
        :layout            => normal_layout,
        :parent            => site_template,
        :is_protected      => true,
        :controller_path   => "/sites/:site_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])

    admin = site.pages.create!(
        :slug              => "site-admin",
        :label             => "Sites Admin",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/sites/admin",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:sites:admin }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:sites_nav }}"
                               }])
    return site
  end
end

