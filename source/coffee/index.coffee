"use strict"

$(document).ready ->
  get_popover_placement = (pop, dom_el) ->
    width = window.innerWidth
    return "bottom"  if width < 500
    left_pos = $(dom_el).offset().left
    return "right"  if width - left_pos > 400
    "left"

  IndexModel = ->
    self = this

    self.items = ko.mapping.fromJS [
      name: "Root"
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
              name: "AZ Nova"
              nodes: []
              children: []
              actions: []
            ,
              name: "Infra"
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

    self.showPopover = (data, event) ->
      $(event.target).popover "show"

    self.hidePopover = (data, event) ->
      $(event.target).popover "hide"

    self # Return ourself

  ko.bindingHandlers.sortable.options.handle = '.btn'
  ko.bindingHandlers.sortable.options.cancel = ''
#  ko.bindingHandlers.sortable.afterMove = (arg, event, ui) ->
#    $("> .popper", ui.item).popover
#      animation: false
#      trigger: "click"
#      delay: 0
#      placement: get_popover_placement

  $.indexModel = new IndexModel()
  ko.applyBindings $.indexModel
#  $(".popper").popover
#    animation: false
#    trigger: "click"
#    delay: 0
#    placement: get_popover_placement
