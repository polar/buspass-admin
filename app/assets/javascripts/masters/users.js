//=require_self

$(function () {
    $("#users .header a, #users .pagination a").live("click", function () {
        $.getScript(this.href);
        return false;
    });
    $("#users_search input").keyup(function () {
        $.get($("#users_search").attr("action"), $("#users_search").serialize(), null, "script");
        return false;
    });
    $("#users .role_checkbox").live("click", function () {
        if (!this.disabled) {
            $(this).parents('form').submit();
        }
    });
    $("#users .password-link").live("click", function () {
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