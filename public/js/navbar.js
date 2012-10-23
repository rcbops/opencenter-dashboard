$(document).ready(function() {
    function NavBarModel() {
        var self = this;
        self.filters = ko.observableArray();
    };

    var nbm = new NavBarModel();
    ko.applyBindings(nbm);

    /* TODO: Figure out how to stuff filters into a
       computed observable so this function gets called
       on filter updates. Possibly using HTTP long-polling
     */

    // FIXME: Add some filters, change this to /filters/, .filters
    $.getJSON('/api/clusters/', function(data) {
        nbm.filters(data.clusters);
        // Activate first navbar item
        $('.navbar * ul.nav li').first().addClass('active');
    });

    // Activate first nav-list item
    $('ul.nav-list li a').parent().first().addClass('active');
});
