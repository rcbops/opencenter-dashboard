"use strict"

$(document).ready ->
  get_popover_placement = (tip, element) ->
    isWithinBounds = (elementPosition) ->
      boundTop < elementPosition.top and boundLeft < elementPosition.left and boundRight > (elementPosition.left + actualWidth) and boundBottom > (elementPosition.top + actualHeight)
    $element = $(element)
    pos = $.extend({}, $element.offset(),
      width: element.offsetWidth
      height: element.offsetHeight
    )
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

    above = isWithinBounds(elementAbove)
    below = isWithinBounds(elementBelow)
    left = isWithinBounds(elementLeft)
    right = isWithinBounds(elementRight)
    (if above then "top" else (if below then "bottom" else (if left then "left" else (if right then "right" else "right"))))

  IndexModel = ->
    self = this

    self.items = ko.mapping.fromJS [
      name: "Workspace"
      nodes: []
      children: [
        name: "Unprovisioned"
        nodes: [
          name: "Unprovisioned"
          status: "unprovisioned"
          actions: []
        ,
          name: "Unprovisioned"
          status: "unprovisioned"
          actions: []
        ]
        children: []
        actions: []
      ,
        name: "Support"
        nodes: []
        children: []
        actions: [
          name: "Create Chef Server"
          action: (data) ->
            data.nodes.mappedCreate ko.mapping.fromJS
              name: "Chef1"
              status: "good"
              actions: [
                name: "Update cookbooks"
                action: (data) ->
                  console.log data
              ]
        ]
      ]
      actions: [
        name: "Add Nova Cluster"
        action: (data) ->
          data.children.mappedCreate ko.mapping.fromJS
            name: "Nova Cluster 1"
            nodes: []
            children: [
              name: "Infra"
              nodes: []
              children: []
              actions: []
            ,
              name: "AZ Nova"
              nodes: []
              children: []
              actions: []
            ]
            actions: [
              name: "Create AZ"
              action: (data) ->
                data.children.mappedCreate ko.mapping.fromJS
                  name: "New AZ"
                  nodes: []
                  children: []
                  actions: []
            ]
      ]
    ]

    self.statusColor = (status) ->
      switch status
        when "unprovisioned"
          return "#3A87AD"
        when "good"
          return "#468847"
        when "alert"
          return "#F89406"
        when "error"
          return "#B94A48"

    self.statusLabel = (status) ->
      switch status
        when "unprovisioned"
          return "label-info"
        when "good"
          return "label-success"
        when "alert"
          return "label-warning"
        when "error"
          return "label-important"

    self.statusButton = (status) ->
      switch status
        when "unprovisioned"
          return "btn-info"
        when "good"
          return "btn-success"
        when "alert"
          return "btn-warning"
        when "error"
          return "btn-danger"

    self # Return ourself

  popoverOptions =
    delay: 0
    trigger: "hover"
    animation: true
    placement: get_popover_placement

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

  $.indexModel = new IndexModel()
  ko.applyBindings $.indexModel
