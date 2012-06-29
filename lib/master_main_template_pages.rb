module PageUtils
  def self.ensure_master_main_site_template
    site = Cms::Site.find_by_identifier("busme-main-template")

    return site unless site.nil?

    site = Cms::Site.create!(
        :path       => "main",
        :identifier => "busme-main-template",
        :label      => "Master Main Pages Template",
        :hostname   => "busme.us"
    )

    layout = site.layouts.create!(
        :identifier => "default",
        :app_layout => "application",
        :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

    normal_layout = site.layouts.create!(
        :identifier => "normal-layout",
        :app_layout => "masters/normal-layout",
        :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "masters/map-layout",
        :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

    root = site.pages.create!(
        :slug              => "busme-main-template-root", # Must be changed on copy
        :label             => "Welcome",
        :layout            => map_layout,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:deployments:main }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:main_nav }}"
                               }])

    help = site.pages.create!(
        :slug              => "help",
        :label             => "Help",
        :layout            => normal_layout,
        :is_protected      => false,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "Help for your Master Plan"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:admin_nav }}"
                               }])

    user_sign_up = site.pages.create!(
        :slug              => "sign-up",
        :label             => "Sign Up",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :controller_path   => "/masters/:master_id/main/mydevise/registrations",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:users:sign-up }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:main_nav }}"
                               }])

    user_sign_in = site.pages.create!(
        :slug              => "sign-in",
        :label             => "Sign In",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :controller_path   => "/masters/:master_id/main/mydevise/sessions/new",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:users:sign-in }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:main_nav }}"
                               }])

    downloads = site.pages.create!(
        :slug              => "downloads",
        :label             => "Downloads",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :controller_path   => "/masters/:master_id/main/downloads",
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "{{ cms:bus:downloads }}"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:navigation:main_nav }}"
                               }])
    return site
  end
end
