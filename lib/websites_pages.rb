module PageUtils
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
        :content    => "{{ cms:layout:left }}\n{{ cms:page:content:rich_text }}\n{{ cms:layout:bottom }}")

    normal_layout = site.layouts.create!(
        :identifier => "normal-layout",
        :app_layout => "websites/normal-layout",
        :content    =>
            "<!--
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
{{ cms:layout:bottom }}")

    root          = site.pages.create!(
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
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
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
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
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
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
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
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])


    index = site.pages.create!(
        :slug              => "all-websites",
        :label             => "All Sites",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/websites",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])

    myindex = site.pages.create!(
        :slug              => "my-websites",
        :label             => "My Sites",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/websites/my_index",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:my_index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])

    new_site      = site.pages.create!(
        :slug              => "new-website",
        :label             => "New Site",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/websites/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:new }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])

    # This page will not be considered in the navigation because the slug ends in template.
    site_template = site.pages.create!(
        :slug              => "website-template",
        :label             => "Will be replaced",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/websites/:site_id/show",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])

    site_edit_template = site.pages.create!(
        :slug              => "edit",
        :label             => "Will be replaced",
        :layout            => normal_layout,
        :parent            => site_template,
        :is_protected      => true,
        :controller_path   => "/websites/:site_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])

    admin = site.pages.create!(
        :slug              => "websites-admin",
        :label             => "Sites Admin",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :controller_path   => "/websites/admin",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:websites:admin }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:websites_nav }}"
                               }])
    return site
  end
end
