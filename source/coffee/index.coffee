"use strict"

# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
    $.getJSON "http://roush.propter.net:8080/nodes/2/tree", (data) =>
      @items = ko.mapping.fromJS [data.tree]

    @statusColor = (status) ->
      switch status
        when "unprovisioned"
          return "#3A87AD"
        when "good"
          return "#468847"
        when "alert"
          return "#F89406"
        when "error"
          return "#B94A48"

    @statusLabel = (status) ->
      switch status
        when "unprovisioned"
          return "label-info"
        when "good"
          return "label-success"
        when "alert"
          return "label-warning"
        when "error"
          return "label-important"

    @statusButton = (status) ->
      switch status
        when "unprovisioned"
          return "btn-info"
        when "good"
          return "btn-success"
        when "alert"
          return "btn-warning"
        when "error"
          return "btn-danger"

    @sections = ko.observableArray [
      name: "Workspace"
      template: "indexTemplate"
    ,
      name: "Profile"
      template: "profileTemplate"
    ,
      name: "Settings"
      template: "settingsTemplate"
    ]

    @section = ntrapy.selector @sections, (data) ->
      # Do something on selection
    , @sections()[0] # Set default

    @ # Return ourself

  popoverOptions =
    delay: 0
    trigger: "hover"
    animation: true
    placement: ntrapy.get_popover_placement

  ko.bindingHandlers.popper =
    init: (element, valueAccessor) ->
      $(element).popover popoverOptions

  ko.bindingHandlers.sortable.options =
    handle: ".btn"
    cancel: ""
    opacity: 0.35
    tolerance: "pointer"
    start: (event, ui) ->
      $(ui.item).find('button[data-bind*="popper"]')
        .popover("disable")
        .popover "hide"

  ko.applyBindings new IndexModel()
