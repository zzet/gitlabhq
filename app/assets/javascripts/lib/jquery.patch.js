(function($) {
    $.patch = function(url, data, callback) {
        $.ajax({
            type: "PATCH",
            url: url,
            data: JSON.stringify(data),
            dataType: 'json',
            contentType: 'application/json',
            success: function(result) {
                if(callback) {
                    callback.call(result);
                }
            }
        });

        return this;
    };
})(jQuery);