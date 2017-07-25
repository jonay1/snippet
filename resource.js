(function($, g) {
	var config = {
		contextpath : "http://localhost:8004",
	};

	var http = {
		config : config,
		post : function(url, data, config) {
			$.extend(config, {
				type : "POST"
			});
			return ajax(url, data, config);
		},
		get : function(url, data, config) {
			$.extend(config, {
				type : "GET"
			});
			return ajax(url, data, config);
		},
		hooks : {
			beforeSend : function() {
			},
			afterSend : function() {
			},
			processData : function(result, resolve, reject) {
				resolve(result);
			}
		}
	};
	var defaults = {
		async : true,
		type : "POST",
		datatype : "json",
		contentType : "application/json",
		timeout : 30000,
		beforeSend : function() {
			http.hooks.beforeSend.call(this);
		},
		success : function(result, status, xhr) {
			http.hooks.processData.call(this, result, dtd.resolve, dtd.reject);
		},
		error : function(result, error) {
			throw result.statusText;
		},
		complete : function(req, status) {
			http.hooks.afterSend(this);
		}
	};
	function ajax(url, postData, config) {
		var dtd = $.Deferred(), data, options = {
			url : config.contextpath + url,
			data : JSON.stringify(postData)
		};
		options = $.extend({}, defaults, options, config);
		$.ajax(options);
		return dtd.promise();
	}
	g.$http = http;
})(jQuery, this);
