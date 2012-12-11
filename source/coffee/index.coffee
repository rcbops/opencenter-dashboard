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

    self.items = ko.mapping.fromJS([
      id: 1
      name: "root"
      nodes: [
        id: 2
        name: "Unprovisioned"
        status: "unprovisioned"
      ,
        id: 3
        name: "Unprovisioned"
        status: "unprovisioned"
      ]
      children: [
        id: 4
        name: "Nova Cluster 1"
        nodes: [
          id: 5
          name: "Chef1"
          status: "good"
        ]
        children: [
          id: 6
          name: "AZ1"
          nodes: [
            id: 7
            name: "Controller1"
            status: "good"
          ,
            id: 8
            name: "Compute1"
            status: "alert"
          ,
            id: 9
            name: "Compute2"
            status: "error"
          ]
          children: []
        ,
          id: 10
          name: "AZ2"
          nodes: [
            id: 11
            name: "Controller1"
            status: "alert"
          ,
            id: 12
            name: "Compute1"
            status: "alert"
          ]
          children: []
        ]
      ,
        id: 13
        name: "Swift Cluster 1"
        nodes: []
        children: [
          id: 14
          name: "Zone1"
          nodes: []
          children: []
        ,
          id: 15
          name: "Zone2"
          nodes: []
          children: []
        ,
          id: 16
          name: "Zone3"
          nodes: []
          children: []
        ,
          id: 17
          name: "Zone4"
          nodes: []
          children: []
        ,
          id: 18
          name: "Zone5"
          nodes: [
            id: 13
            name: "Proxy1"
            status: "good"
          ]
          children: []
        ]
      ]
    ])

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

    self.action = (data, event) ->
      console.log data
      mapping = nodes:
        key: (data) ->
          ko.utils.unwrapObservable data.id

      ko.mapping.fromJS data, mapping, self.items

    self # Return ourself

  ko.bindingHandlers.sortable.options.handle = '.btn'
  ko.bindingHandlers.sortable.options.cancel = ''

  $.indexModel = new IndexModel()
  ko.applyBindings $.indexModel
  $(".popper").popover
    animation: false
    trigger: "hover"
    delay: 0
    placement: get_popover_placement
