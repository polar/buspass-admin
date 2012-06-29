//=require_self

$(function () {
    $("#muni_admins .header a, #muni_admins .pagination a").live("click", function () {
        $.getScript(this.href);
        return false;
    });
    $("#muni_admins_search input").keyup(function () {
        $.get($("#muni_admins_search").attr("action"), $("#muni_admins_search").serialize(), null, "script");
        return false;
    });
    $("#muni_admins .role_checkbox").live("click", function () {
        if (!this.disabled) {
            $(this).parents('form').submit();
        }
    });
    $("#muni_admins .password-link").live("click", function () {
       $.getScript(this.href);
       var selector ="#password-modal-"+this.getAttribute("data-id");
       $(selector).modal("show");
       return false;
    });
    $(".modal").live('show', function () {
            $(".modal .error_explanation").html("");
        }
    );
});