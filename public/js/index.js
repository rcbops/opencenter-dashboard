$(document).ready(function() {
    var IndexModel = function() {
        // Store for convenience
        var self = this;
        var host = "http://thor.local:8080"

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
        $.getJSON(host + '/filters/', function(res) {
            self.filters(res.filters);
        });

        // Node getter/setter
        self.node = selector(self.nodes, function(data) {
            if(data && data['id']) {
                // Query adventures
                $.getJSON(host + '/nodes/' + data['id'] + '/adventures',
                          function(res) {self.adventures(res.adventures)}
                         );
            }
            else {
                // Blank adventures
                self.adventures([]);
            }
        });

        // Node properties
        self.nProp = ko.computed(function() {
            return toArray(self.node());
        });

        // Filter getter/setter
        self.filter = selector(self.filters, function(data) {
            if(data && data['expr']) {
                // Evaluate filter and update nodes
                $.post(host + '/nodes/filter',
                       JSON.stringify({ filter: data['expr'] }),
                       function(res) {self.nodes(res.nodes)}
                      );
            }
            // Blank node
            self.node({});
        });

        self.adventurate = function(data) {
            if(data && data['id']) {
                $.post(host + '/adventures/' + data['id'] + '/execute',
                       JSON.stringify({
                           nodes: [self.node()['id']]
                       }),
                       function(res) {console.log(res)}
                      );
            }
        };
    };

    // Store model variable for convenience
    var indexModel = new IndexModel();
    ko.applyBindings(indexModel);
});
