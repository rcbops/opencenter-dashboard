$(document).ready(function() {
    function NavBarModel() {
        var self = this;
        self.filters = ko.observableArray();

        /* TODO: Figure out how to stuff filters into a
           computed observable so this function gets called
           on filter updates. Possibly using HTTP long-polling
        */
        $.getJSON('/api/filters/', function(data) {
            self.filters(data.filters);
            // Activate first navbar item
            $('.navbar * ul.nav li').first().addClass('active');
        });

        self.nodes = ko.computed(function() {
            // Grab nodes from filter
            $.post()
        });
    };

    var nbm = new NavBarModel();
    ko.applyBindings(nbm);

    // Activate first nav-list item
    $('ul.nav-list li a').parent().first().addClass('active');
});
