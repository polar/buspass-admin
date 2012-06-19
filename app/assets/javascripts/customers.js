//=require_self

$(function () {
    $("#customers header a, #customers .pagination a").live("click", function () {
        $.getScript(this.href);
        return false;
    });
    $("#customers_search input").keyup(function () {
        $.get($("#customers_search").attr("action"), $("#customers_search").serialize(), null, "script");
        return false;
    });
    $("#customers .role_checkbox").live("click", function () {
        if (!this.disabled) {
            $(this).parents('form').submit();
        }
    });
    $("#customers .password-link").live("click", function () {
        console.log("GETTING PASSWORD for "+this.getAttribute("data-id"));
       $.getScript(this.href);
       var selector ="#password-modal-"+this.getAttribute("data-id");
       $(selector).modal("show");
       return false;
    });
});