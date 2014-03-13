(function($) {
    $.delete = function(url, data, callback) {
        $.ajax({
            url: url,
            data: data,
            type: 'DELETE',
            success: function(result) {
                callback.call(result);
            }
        });
    }
})(jQuery);