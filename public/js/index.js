$(document).ready(function() {
    // Overwrite $.post with application/json version
    $.post = function(url, data, callback) {
        return jQuery.ajax({
            type: "POST",
            url: url,
            data: data,
            success: callback,
            dataType: "json",
            contentType: "application/json; charset=utf-8"
        });
    };

    selector = function(callback) {
        var parent = this;
        return ko.computed({
            read: function() {
                if(!parent.sub)
                    parent.sub = ko.observable();
                return parent.sub();
            },
            write: function(data) {
                parent.sub(data);
                callback(data);
            },
            deferEvaluation: true,
            owner: parent
        })
    };

    var IndexModel = function() {
        // Store for convenience
        var self = this;

        // Main arrays
        self.filters = ko.observableArray();
        self.nodes = ko.observableArray();
        self.adventures = ko.observableArray();
        self.facts = ko.observableArray();

        /*
          TODO: Figure out how to stuff filters into a
          computed observable so this function gets called
          on filter updates. Possibly using HTTP long-polling
        */

        // Initialize filters
        $.getJSON('http://localhost:8080/filters/', function(data) {
            self.filters(data.filters);
        });

        self.filter = selector(function(data) {
            if(data && data['expr']) {
                $.post('http://localhost:8080/nodes/filter',
                       JSON.stringify({ filter: data['expr'] }),
                       function(res) {self.nodes(res.nodes)}
                      );
            }
        });

        self.node = selector(function(data) { });
    };

    var indexModel = new IndexModel();
    ko.applyBindings(indexModel);
});
