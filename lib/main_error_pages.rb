module PageUtils
  def self.ensure_main_error_pages_site

    site = Cms::Site.find_by_identifier("busme-main-error")

    return site unless site.nil?

    site = Cms::Site.create!(
        :path       => "/",
        :identifier => "busme-main-error",
        :label      => "Busme Main Error Page Set",
        :hostname   => "errors.busme.us",    # We just need something different.
        :protected  => true
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

    map_layout = site.layouts.create!(
        :identifier => "map-layout",
        :app_layout => "websites/map-layout",
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
                                   :content    => "This page will never be displayed. It serves as the root for the error pages."
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/websites_nav }}"
                               }])

    notfound = site.pages.create!(
        :slug              => "not_found",
        :label             => "Page Not Found",
        :layout            => normal_layout,
        :parent            => root,
        :is_protected      => true,
        :error_status      => 404,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "The page you were looking for doesn't exist"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/websites_nav }}"
                               }])

    permission = site.pages.create!(
        :slug              => "permission_denied",
        :label             => "Permission Denied",
        :layout            => normal_layout,
        :is_protected      => true,
        :parent            => root,
        :error_status      => 403,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "You are not allowed to access the requested page"
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/websites_nav }}"
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
                                   :content    => "{{ cms:bus:render:navigation/websites_nav }}"
                               }])

    overlimit = site.pages.create!(
        :slug              => "over_limit",
        :label             => "Over Limit",
        :layout            => normal_layout,
        :is_protected      => true,
        :error_status      => 200,
        :parent            => root,
        :blocks_attributes => [{
                                   :identifier => "content",
                                   :content    => "You are over the limit of how many sites you can make. Please contact us."
                               },
                               {
                                   :identifier => "left",
                                   :content    => "{{ cms:bus:render:navigation/websites_nav }}"
                               }])
  end

end