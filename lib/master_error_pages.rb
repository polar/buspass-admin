module PageUtils
  def self.ensure_master_error_site_template

    site = Cms::Site.find_by_identifier("busme-master-error-template")

    return site unless site.nil?

    site = Cms::Site.create!(
        :path       => "/errors",
        :identifier => "busme-master-error-template",
        :label      => "Busme Master Error Page Set Template",
        :hostname   => "errors.masters.#{Rails.application.base_host}",    # just need something different
        :protected  => true
    )

    layout = site.layouts.create!(
        :identifier => "default",
        :app_layout => "application",
        :content    => "{{ cms:layout:left }}\n{{ cms:page:content:rich_text }}\n{{ cms:layout:bottom }}")

    normal_layout = site.layouts.create!(
        :identifier => "normal-layout",
        :app_layout => "masters/normal-layout",
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

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "masters/map-layout",
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

    root = site.pages.create!(
        :slug              => "root",
        :label             => "Error Pages",
        :layout            => normal_layout,
        :is_protected      => true,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "The is the root page for standard errors. This page will never be displayed."
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    notfound = site.pages.create!(
        :slug              => "not_found",
        :label             => "Page Not Found",
        :layout            => normal_layout,
        :is_protected      => true,
        :error_status      => 404,
        :parent => root,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "The page you were looking for doesn't exist"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])


    permission = site.pages.create!(
        :slug              => "permission_denied",
        :label             => "Permission Denied",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent => root,
        :error_status      => 403,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "You are not allowed to access the requested page"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])

    internal = site.pages.create!(
        :slug              => "internal_error",
        :label             => "Internal Error",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :error_status      => 500,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "We have experienced an internal error. Our staff has been notified."
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/admin_nav }}"
                               }])
  end

end