$(document).ready(function() {
    var IndexModel = function() {
        // Store for convenience
        var self = this;
        var host = "http://localhost:8080"

        // Main arrays
        //self.filters = ko.observableArray();
        //self.nodes = ko.observableArray();
        //self.adventures = ko.observableArray();
        //self.facts = ko.observableArray();

        /*
          TODO: Figure out how to stuff filters into a
          computed observable so this function gets called
          on filter updates. Possibly using HTTP long-polling
        */

        // Initialize filters
        //$.getJSON(host + '/filters/', function(res) {
        //    self.filters(res.filters);
        //});

        // Node getter/setter
        //self.node = selector(self.nodes, function(data) {
        //    if(data && data['id']) {
        //        // Query adventures
        //        $.getJSON(host + '/nodes/' + data['id'] + '/adventures',
        //                  function(res) {self.adventures(res.adventures)}
        //                 );
        //    }
        //    else {
        //        // Blank adventures
        //        self.adventures([]);
        //    }
        //});

        // Node properties
        //self.nProp = ko.computed(function() {
        //    return toArray(self.node());
        //});

        // Filter getter/setter
        //self.filter = selector(self.filters, function(data) {
        //    if(data && data['expr']) {
        //        // Evaluate filter and update nodes
        //        $.post(host + '/nodes/filter',
        //               JSON.stringify({ filter: data['expr'] }),
        //               function(res) {self.nodes(res.nodes)}
        //              );
        //    }
        //    // Blank node
        //    self.node({});
        //});
        //
        //self.adventurate = function(data) {
        //    if(data && data['id']) {
        //        $.post(host + '/adventures/' + data['id'] + '/execute',
        //               JSON.stringify({
        //                   nodes: [self.node()['id']]
        //               }),
        //               function(res) {console.log(res)}
        //              );
        //    }
        //};

        self.items = ko.observable({
            name: 'root',
            nodes: ko.observableArray([
                { name: 'Unprovisioned', status: 'unprovisioned' },
                { name: 'Unprovisioned', status: 'unprovisioned' }
            ]),
            children: ko.observableArray([
                {
                    name: 'AZ1',
                    nodes: ko.observableArray([
                        { name: 'AZ1-Chef', status: 'good' }
                    ]),
                    children: ko.observableArray([
                        {
                            name: 'Nova1',
                            nodes: ko.observableArray([
                                { name: 'Controller1', status: 'good' },
                                { name: 'Compute1', status: 'alert' },
                                { name: 'Compute2', status: 'error' }
                            ]),
                            children: ko.observableArray([])
                        },
                        {
                            name: 'Swift1',
                            nodes: ko.observableArray([
                                { name: 'Proxy1', status: 'alert' },
                                { name: 'Storage1', status: 'alert' }
                            ]),
                            children: ko.observableArray([])
                        }
                    ])
                },
                {
                    name: 'AZ2',
                    nodes: ko.observableArray([
                        { name: 'AZ2-Chef', status: 'alert' }
                    ]),
                    children: ko.observableArray([
                        {
                            name: 'Nova1',
                            nodes: ko.observableArray([]),
                            children: ko.observableArray([])
                        },
                        {
                            name: 'Nova2',
                            nodes: ko.observableArray([]),
                            children: ko.observableArray([])
                        }
                    ])
                }
            ])
        });

        self.statusColor = function(status) {
            switch(status) {
                case 'unprovisioned':
                return '#3A87AD'; // label-info
                break;
                case 'good':
                return '#468847'; // label-success
                break;
                case 'alert':
                return '#F89406'; // label-warning
                break;
                case 'error':
                return '#B94A48'; // label-important
                break;
            };
        };

        self.statusLabel = function(status) {
            switch(status) {
            case 'unprovisioned':
                return 'label-info';
                break;
            case 'good':
                return 'label-success';
                break;
            case 'alert':
                return 'label-warning';
                break;
            case 'error':
                return 'label-important';
                break;
            };
        };

        self.statusButton = function(status) {
            switch(status) {
            case 'unprovisioned':
                return 'btn-info';
                break;
            case 'good':
                return 'btn-success';
                break;
            case 'alert':
                return 'btn-warning';
                break;
            case 'error':
                return 'btn-danger';
                break;
            };
        };
    };

    // Store model variable for convenience
    var indexModel = new IndexModel();
    ko.applyBindings(indexModel);

    $("a[rel=popover]")
      .popover()
      .click(function(e) {
        e.preventDefault()
})
});
