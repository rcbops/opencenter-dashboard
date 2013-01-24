"use strict"

# Create and store namespace
ntrapy = exports?.ntrapy ? @ntrapy = {}

ntrapy.statusColor = (status) ->
  switch status
    when "unprovisioned"
      return "#3A87AD"
    when "good"
      return "#468847"
    when "alert"
      return "#F89406"
    when "error"
      return "#B94A48"

ntrapy.statusLabel = (status) ->
  switch status
    when "unprovisioned"
      return "label-info"
    when "good"
      return "label-success"
    when "alert"
      return "label-warning"
    when "error"
      return "label-important"

ntrapy.statusButton = (status) ->
  switch status
    when "unprovisioned"
      return "btn-info"
    when "good"
      return "btn-success"
    when "alert"
      return "btn-warning"
    when "error"
      return "btn-danger"

# Overwrite $.post with application/json version
$.post = (url, data, callback) ->
  $.ajax
    type: "POST"
    url: url
    data: data
    success: callback
    dataType: "json"
    contentType: "application/json; charset=utf-8"

ntrapy.selector = (cb, def) ->
  @selected = ko.observable def ? {} unless @selected?
  cb def if cb? and def?
  ko.computed
    read: =>
      @selected()
    write: (data) =>
      @selected data
      cb data if cb?

# Object -> Array mapper
ntrapy.toArray = (obj) ->
  array = []
  for prop of obj
    if obj.hasOwnProperty(prop)
      array.push
        key: prop
        value: obj[prop]

  array # Return mapped array

ntrapy.getPopoverPlacement = (tip, element) ->
  isWithinBounds = (elementPosition) ->
    boundTop < elementPosition.top and boundLeft < elementPosition.left and boundRight > (elementPosition.left + actualWidth) and boundBottom > (elementPosition.top + actualHeight)
  $element = $ element
  pos = $.extend {}, $element.offset(),
    width: element.offsetWidth
    height: element.offsetHeight
  actualWidth = 283
  actualHeight = 117
  boundTop = $(document).scrollTop()
  boundLeft = $(document).scrollLeft()
  boundRight = boundLeft + $(window).width()
  boundBottom = boundTop + $(window).height()
  elementAbove =
    top: pos.top - actualHeight
    left: pos.left + pos.width / 2 - actualWidth / 2

  elementBelow =
    top: pos.top + pos.height
    left: pos.left + pos.width / 2 - actualWidth / 2

  elementLeft =
    top: pos.top + pos.height / 2 - actualHeight / 2
    left: pos.left - actualWidth

  elementRight =
    top: pos.top + pos.height / 2 - actualHeight / 2
    left: pos.left + pos.width

  above = isWithinBounds elementAbove
  below = isWithinBounds elementBelow
  left = isWithinBounds elementLeft
  right = isWithinBounds elementRight
  if above then "top" else if below then "bottom" else if left then "left" else if right then "right" else "right"
