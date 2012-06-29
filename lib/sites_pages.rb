module PageUtils
  def ensure_sites_pages_site
    site = Cms::Site.find_by_identifier("busme-main")

    if site.nil?
      site = Cms::Site.create!(
          :path       => "/main",
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
          :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

      root = site.pages.create!(
          :slug              => "",
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
                                 }
          ])

      help = site.pages.create!(
          :slug              => "help",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Help Busme!"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      index = site.pages.create!(
          :slug              => "sites",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:sites:index }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      myindex = site.pages.create!(
          :slug              => "my-sites",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:sites:my_index }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      # This page will not be considered in the navigation because the slug ends in template.
      site_template = site.pages.create!(
          :slug              => "site-template",
          :label             => "Will be replaced",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:sites:show }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      # This page will not be considered in the navigation because the slug ends in template.
      site_edit_template = site.pages.create!(
          :slug              => "site-edit-template",
          :label             => "Will be replaced",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:sites:edit }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])
    end
  end

  def ensure_sites_customers_site
    site = Cms::Site.find_by_identifier("busme-customers")

    if site.nil?
      site = Cms::Site.create!(
          :path       => "/main",
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
          :content    => "<% content_for :left do %>\n\t{{ cms:bus:page:left:text }}\n<% end %>\n{{ cms:page:content:rich_text }}")

      root = site.pages.create!(
          :slug              => "",
          :label             => "Welcome",
          :layout            => normal_layout,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:customers:index }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      help = site.pages.create!(
          :slug              => "help",
          :label             => "Help",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "Help with Customers"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      signup = site.pages.create!(
          :slug              => "",
          :label             => "Sign Up",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:customers:sign_up }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      signin = site.pages.create!(
          :slug              => "",
          :label             => "Sign Up",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:customers:sign_in }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])

      admin = site.pages.create!(
          :slug              => "",
          :label             => "Admin",
          :layout            => normal_layout,
          :parent            => root,
          :is_protected      => true,
          :blocks_attributes => [{
                                     :identifier => "content",
                                     :content    => "{{ cms:bus:customers:admin }}"
                                 },
                                 {
                                     :identifier => "left",
                                     :content    => "{{ cms:bus:navigation:sites_nav }}"
                                 }
          ])
    end

  end
end