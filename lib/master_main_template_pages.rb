module PageUtils
  def self.ensure_master_main_site_template
    site = Cms::Site.find_by_identifier("busme-main-template")

    return site unless site.nil?

    site = Cms::Site.create!(
        :path       => "main",
        :identifier => "busme-main-template",
        :label      => "Master Main Pages Template",
        :hostname   => "#{Rails.application.base_host}",
        :protected  => true
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
        :app_layout => "masters/active/normal-layout",
        :content => layout_content)

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "masters/active/map-layout",
        :content => layout_content)

    root = site.pages.create!(
        :slug              => "busme-main-template-root", # Must be changed on copy
        :label             => "Welcome",
        :layout            => map_layout,
        :is_protected      => true,
        :controller_path   => "/masters/:master_id/active",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:render:masters/active/show }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    help = site.pages.create!(
        :slug              => "help",
        :label             => "Help",
        :layout            => normal_layout,
        :is_protected      => false,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "Help for General Users"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    sitemap = site.pages.create!(
        :slug              => "sitemap",
        :label             => "Sitemap",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => help,
        :controller_path => "/masters/:master_id/sitemap/main",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "<h1>Sitemap for {{ cms:bus:master:name }}</h1>\n{{ cms:bus:render:masters/sitemap/main }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    user_sign_in = site.pages.create!(
        :slug              => "user-sign-in",
        :label             => "Sign In",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :controller_path   => "/masters/:master_id/user_sign_in",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:render:sessions/new_user }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    user_registrations = site.pages.create!(
        :slug              => "user_registrations",
        :label             => "User Registrations",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :is_published      => false, # Won't go into menu
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "This page is not meant to be displayed}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    user_new = site.pages.create!(
        :slug              => "new",
        :label             => "New User",
        :layout            => normal_layout,
        :parent            => user_registrations,
        :is_protected      => true,
        :is_published      => false, # Won't go into menu
        :controller_path   => "/masters/:master_id/user_registrations/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/user_registrations/new }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    user_edit = site.pages.create!(
        :slug              => "edit",
        :label             => "Edit User",
        :layout            => normal_layout,
        :parent            => user_registrations,
        :is_protected      => true,
        :is_published      => false, # Won't go into menu
        :controller_path   => "/masters/:master_id/user_registrations/:user_id/edit",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content => "{{ cms:bus:render:masters/user_registrations/edit }}"
                               },
                               {
                                   :identifier => "left",
                                   :content => "{{ cms:bus:render:navigation/main_nav }}"
                               }])

    downloads = site.pages.create!(
        :slug              => "downloads",
        :label             => "Downloads",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :controller_path   => "/masters/:master_id/downloads",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:render:masters/downloads/index }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/main_nav }}"
                               }])
    return site
  end
end
