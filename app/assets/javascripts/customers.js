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
    $("#customers input[type=checkbox]").live("click", function () {
        console.log($(this).parents('form'))
        $(this).parents('form').submit();
    });
});