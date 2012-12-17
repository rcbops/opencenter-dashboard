"use strict"

# Grab namespace
utils = exports?.utils ? @utils

$ ->
  IndexModel = ->
    @items = ko.mapping.fromJS [
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

    @section = utils.selector @sections(), (data) ->
      console.log data
    , @sections()[0] # Set default

    @ # Return ourself

  popoverOptions =
    delay: 0
    trigger: "hover"
    animation: true
    placement: utils.get_popover_placement

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
