(function($, g) {
    var Router = {
        ddic: "/data8.do"
    };
    // ---------
    var App = {
        base: "",
        remote: "http://localhost:8004",
        path: {
            uri: "/",
            params: {},
            hash: ""
        },
        router: Router
    };
    Date.prototype.format = function(format) {
        var o = {
            "M+": this.getMonth() + 1, // month
            "d+": this.getDate(), // day
            "H+": this.getHours(), // hour
            "m+": this.getMinutes(), // minute
            "s+": this.getSeconds(), // second
            "q+": Math.floor((this.getMonth() + 3) / 3), // quarter
            "S": this.getMilliseconds()
                // millisecond
        };
        if (/(y+)/.test(format))
            format = format.replace(RegExp.$1, (this.getFullYear() + "").substr(4 - RegExp.$1.length));
        for (var k in o)
            if (new RegExp("(" + k + ")").test(format))
                format = format.replace(RegExp.$1, RegExp.$1.length == 1 ? o[k] : ("00" + o[k]).substr(("" + o[k]).length));
        return format;
    };
    // ---------
    var SUCCESS = "000000";
    var divLoading;
    var loadingCount = 0;

    function _showLoading(options) {
        if (options.showloading !== false) {
            if (!divLoading) {
                divLoading = null; // init
            }
            // open divLoading("open");
            loadingCount++;
        }
    }

    function _hideLoading(options) {
        if (options.showloading !== false) {
            if (divLoading) {
                loadingCount--;
                if (loadingCount == 0) {
                    // close divLoading("close");
                }
            }
        }
    }

    function ajax(url, postData, config) {
        var dtd = $.Deferred(),
            data, options = {};
        var defaults = {
            async: true,
            type: "POST",
            datatype: "json",
            contentType: "application/json",
            url: App.remote + url,
            timeout: 30000,
            data: JSON.stringify(postData),
            beforeSend: function() {
                _showLoading(options);
            },
            success: function(result, status, xhr) {
                data = result;
                if (data.code == SUCCESS) {
                    dtd.resolve(result.data);
                } else {
                    if (options.showerror !== false) {
                        $.error(result.message);
                    }
                    dtd.reject(result.code, result.message);
                }
            },
            error: function(result, error) {
                dtd.reject(result.status, result.statusText);
                throw result.statusText;
            },
            complete: function(req, status) {
                _hideLoading(options);
            }
        };
        options = $.extend(options, defaults, config);

        $.ajax(options);

        return dtd.promise();
    }


    // ---------

    function pageInit() {}

    function pageReady() {}

    pageInit();
    $(pageReady);

    g.AppConfig = App;
    g.$ajax = ajax;
})(jQuery, this);
