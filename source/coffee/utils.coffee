"use strict"

# Overwrite $.post with application/json version
$.post = (url, data, callback) ->
  jQuery.ajax
    type: "POST"
    url: url
    data: data
    success: callback
    dataType: "json"
    contentType: "application/json; charset=utf-8"



# Selector wrapper
selector = (parent, callback) ->
  ko.computed
    read: ->
      parent.sub = ko.observable()  unless parent.sub
      parent.sub()

    write: (data) ->
      parent.sub data
      callback data

    deferEvaluation: true
    owner: parent



# Object -> Array mapper
toArray = (obj) ->
  array = []
  for prop of obj
    if obj.hasOwnProperty(prop)
      array.push
        key: prop
        value: obj[prop]

  array


# Fade in on add
self.fadeAdd = (elem) ->
  if elem.nodeType is 1
    $(elem).hide().fadeIn()
    $(elem).children().hide().fadeIn()


# Fade out on remove
self.fadeRemove = (elem) ->
  if elem.nodeType is 1
    $(elem).hide().fadeOut ->
      $(elem).remove()

    $(elem).children().hide().fadeOut ->
      $(elem).remove()

