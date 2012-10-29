$(document).ready(function() {
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
        $.getJSON('http://localhost:8080/filters/', function(res) {
            self.filters(res.filters);
        });

        // Node getter/setter
        self.node = selector(self.nodes, function(data) {
            if(data && data['id']) {
                // Query adventures
                $.getJSON('http://localhost:8080/nodes/' +
                          data['id'] +
                          '/adventures',
                          function(res) {self.adventures(res.adventures)}
                         );
            }
            else {
                // Blank adventures
                self.adventures({});
            }
        });

        // Filter getter/setter
        self.filter = selector(self.filters, function(data) {
            if(data && data['expr']) {
                // Evaluate filter and update nodes
                $.post('http://localhost:8080/nodes/filter',
                       JSON.stringify({ filter: data['expr'] }),
                       function(res) {self.nodes(res.nodes)}
                      );
            }
            // Blank node
            self.node({});
        });
    };

    // Store model variable for convenience
    var indexModel = new IndexModel();
    ko.applyBindings(indexModel);
});
