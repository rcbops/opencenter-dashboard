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

// Selector wrapper
selector = function(parent, callback) {
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
    });
};

// Object -> Array mapper
toArray = function(obj) {
    var array = [];
    for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
            array.push({ key: prop, value: obj[prop] });
        }
    }
    return array;
};
