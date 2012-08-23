/**
 * This JS is for the set up of the Customers Index where a Customer
 * in an AdminRole can delete other Customers.
 */
//=require_self

$(function () {
    $("#customers .header a, #customers .pagination a").live("click", function () {
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