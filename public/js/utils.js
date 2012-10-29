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
selector = function(callback) {
    var parent = this;

    return ko.computed({
        read: function() {
            if(!parent.sub) parent.sub = ko.observable();
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

// Object -> Array mapper
o2a = function(obj) {
    var array = [];
    for (var prop in obj) {
        if (obj.hasOwnProperty(prop)) {
            array.push({ key: prop, value: obj[prop] });
        }
    }
    return array;
};
