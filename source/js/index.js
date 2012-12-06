$(document).ready(function() {
    var IndexModel = function() {
        // Store for convenience
        var self = this;

        self.items = ko.mapping.fromJS([{
            id: 1,
            name: 'root',
            nodes: [
                { id: 2, name: 'Unprovisioned', status: 'unprovisioned' },
                { id: 3, name: 'Unprovisioned', status: 'unprovisioned' }
            ],
            children: [
                {
                    id: 4,
                    name: 'Nova Cluster 1',
                    nodes: [
                        { id: 5, name: 'Chef1', status: 'good' }
                    ],
                    children: [
                        {
                            id: 6,
                            name: 'AZ1',
                            nodes: [
                                { id: 7, name: 'Controller1', status: 'good' },
                                { id: 8, name: 'Compute1', status: 'alert' },
                                { id: 9, name: 'Compute2', status: 'error' }
                            ],
                            children: []
                        },
                        {
                            id: 10,
                            name: 'AZ2',
                            nodes: [
                                { id: 11, name: 'Controller1', status: 'alert' },
                                { id: 12, name: 'Compute1', status: 'alert' }
                            ],
                            children: []
                        }
                    ]
                },
                {
                    id: 13,
                    name: 'Swift Cluster 1',
                    nodes: [],
                    children: [
                        {
                            id: 14,
                            name: 'Zone1',
                            nodes: [],
                            children: []
                        },
                        {
                            id: 15,
                            name: 'Zone2',
                            nodes: [],
                            children: []
                        },
                        {
                            id: 16,
                            name: 'Zone3',
                            nodes: [],
                            children: []
                        },
                        {
                            id: 17,
                            name: 'Zone4',
                            nodes: [],
                            children: []
                        },
                        {
                            id: 18,
                            name: 'Zone5',
                            nodes: [
                                { id: 13, name: 'Proxy1', status: 'good' }
                            ],
                            children: []
                        }
                    ]
                }
            ]
        }]);

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

        self.showPopover = function(data, event) {
            $(event.target).popover('show');
        };

        self.hidePopover = function(data, event) {
            $(event.target).popover('hide');
        };

        self.action = function(data, event) {
            console.log(data);
            var mapping = {
                'nodes': {
                    key: function(data) {
                        return ko.utils.unwrapObservable(data.id);
                    }
                }
            };

            ko.mapping.fromJS(data, mapping);
        };
    };

    // Store model variable for convenience
    $.indexModel = new IndexModel();
    ko.applyBindings($.indexModel);

    function get_popover_placement(pop, dom_el) {
        var width = window.innerWidth;

        if (width < 500)
            return 'bottom';

        var left_pos = $(dom_el).offset().left;

        if (width - left_pos > 400)
            return 'right';

        return 'left';
    }

    $('.popper')
        .popover({
            animation: false,
            trigger: 'hover',
            delay: 0,
            placement: get_popover_placement
        });
});
