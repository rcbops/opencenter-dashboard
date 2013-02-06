# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
    @getData = (url, cb) ->
      $.getJSON url, (data) ->
        cb data if cb?

    @mapData = (data, pin, map={}, wrap=true) ->
      data = [data] if wrap?
      ko.mapping.fromJS data, map, pin

    @getMappedData = (url, pin, map={}, wrap=true) =>
      @getData url, (data) => @mapData(data, pin, map, wrap)

    @getNodes = (data, pin, keyed={}, root={}) ->
      # Index node list by ID
      for node in data.nodes
        keyed[node.id] = node

      # Step through IDs
      for id of keyed
        node = keyed[id]
        pid = node.facts?.parent_id
        if pid? # Has parent?
          pnode = keyed?[pid]
          pnode.children ?= [] # Initialize if first child
          pnode.children.push node # Add to parent's children
        else # Must be root node
          root = node # Point at it

      pin keyed if pin?
      children: root

    # Be sure to use a harness for the chillin'folk!
    #@getTree = (start) =>
    #  if start?.children?
    #    @getTree c for c in start.children

    @wsTemp = ko.observableArray()
    @wsItems = ko.computed =>
      @wsTemp()?[0]?.children ? []

    @wsPlans = ko.observableArray()

    # TODO: Map from data source
    @siteNav = ko.observableArray [
      name: "Workspace"
      template: "indexTemplate"
    #,
    #  name: "Profile"
    #  template: "profileTemplate"
    #,
    #  name: "Settings"
    #  template: "settingsTemplate"
    ]

    mapping =
      children:
        key: (data) ->
          ko.utils.unwrapObservable data.id
        create: (options) ->
          createNode options

    createNode = (options) =>
      @node = options.data
      ko.mapping.fromJS
        servers: (n for n in @node.children ? [] when "agent" in n.facts.backends)
        containers: (n for n in @node.children ? [] when "container" in n.facts.backends)
        actions: []
        status: "good"
      , {}, ko.mapping.fromJS @node, mapping

    @wsKeys = ko.observable()

    ntrapy.pollTree = =>
      unless ntrapy.poller? then ntrapy.poller = setInterval @getMappedData, @config.interval, "/roush/nodes/1/tree", @wsTemp, mapping

    ntrapy.stopTree = ->
      ntrapy.poller = clearInterval ntrapy.poller if ntrapy.poller?

    @getData "/api/config", (data) =>
      # Store config
      @config = data

      # Load initial data, and poll every config.interval ms
      #@getMappedData "/roush/nodes/1/tree", @wsTemp, mapping
      #ntrapy.pollTree()
      @getData "/roush/nodes", (data) =>
        @mapData @getNodes(data, @wsKeys), @wsTemp, mapping

    @siteActive = ntrapy.selector (data) =>
      null
      #switch data.name
      #  when "Workspace"
      #    @getMappedData "/roush/nodes/1/tree", @wsTemp, mapping
    , @siteNav()[0] # Set to first by default

    # Template accessor that avoids data-loading race
    @getTemplate = ko.computed =>
      @siteActive()?.template ? {} # TODO: Needs .template?() if @siteNav is mapped

    @getIndexTemplate = ko.computed =>
      name: "indexItemTemplate"
      foreach: @wsItems

    @getPlans = ko.computed =>
      if not @wsPlans()?.plan?.length
        return null

      ret = []
      ret.push (ntrapy.toArray n?.args)... for n in @wsPlans()?.plan
      ret

    @getActions = (node) =>
      if ntrapy.poller? then ntrapy.stopTree() else ntrapy.pollTree()
      @getData "/roush/nodes/#{node.id()}/adventures", (data) ->
        node.actions (n for n in data.adventures)

    @doAction = (object, action) =>
      ntrapy.post "/roush/adventures/#{action.id}/execute",
        JSON.stringify node: object.id()
      , (data) -> # success handler
        null #TODO: Use success for something
      , (jqXHR, textStatus, errorThrown) => # error handler
        switch jqXHR.status
          when 409 # Need more data
            @wsPlans JSON.parse jqXHR.responseText
            @wsPlans().node = object.id()
            $("#indexInputModal").modal "show"
          else
            console.log "Error (#{jqXHR.status}): ", errorThrown

    $('#inputForm').validate
      debug: true
      highlight: (element) ->
        $(element).closest('.control-group').removeClass('success').addClass('error')
      success: (element) ->
        $(element).text('').addClass('valid').closest('.control-group').removeClass('error').addClass('success')
      submitHandler: (form) =>
        $(form).find('.control-group').each (index, element) =>
          key = $(element).find('label').first().text()
          val = $(element).find('input').val()
          for plan in @wsPlans().plan
            if plan?.args?[key]?
              plan.args[key].value = val
        ntrapy.post "/roush/plan/",
          JSON.stringify
            node: @wsPlans().node
            plan: @wsPlans().plan
        , (data) ->
          $("#indexInputModal").modal "hide"
        , (jqXHR, textStatus, errorThrown) ->
          $("#indexInputModal").modal "hide"
          console.log "Error: ", jqXHR.status, textStatus, errorThrown

    @ # Return ourself

  popoverOptions =
    html: true
    delay: 0
    trigger: "hover"
    animation: true
    #placement: ntrapy.getPopoverPlacement

  ko.bindingHandlers.popper =
    init: (el, data) ->
      $(el).on "mouseover", ntrapy.stopTree
      $(el).on "mouseout", ntrapy.pollTree
      opts = popoverOptions
      opts["title"] = ->
        #TODO: Figure out why this fires twice: console.log "title"
        data()?.name?() ? "Details"
      opts["content"] = ->
        """
        <ul>
        <li><strong>ID:</strong> #{data().id()}</li>
        <li><strong>Status:</strong> #{data().status()}</li>
        <li><strong>Adventure:</strong> #{data().adventure_id() ? 'idle'}</li>
        <li><strong>Task:</strong> #{data().task_id() ? 'idle'}</li>
        <li><strong>Backends:</strong><ul>
        #{('<li>' + backend + '</li>' for backend in data().facts.backends()).join('')}
        </ul></li>
        """
      $(el).popover opts

  ko.bindingHandlers.sortable.options =
    handle: ".btn"
    cancel: ""
    opacity: 0.35
    tolerance: "pointer"
    start: (event, ui) ->
      $(ui.item).find('button[data-bind*="popper"]')
        .popover("disable")
        .popover "hide"
      ntrapy.stopTree() # Stop polling on drag start
    stop: (event, ui) ->
      ntrapy.pollTree() # Resume polling

  ko.bindingHandlers.sortable.afterMove = (options) ->
    parent = options.sourceParentNode.attributes["data-id"].value
    ntrapy.post "/roush/facts/",
      JSON.stringify
        key: "parent_id"
        value: parent
        node_id: options.item.id()
    , (data) ->
      console.log "Success: ", data
    , (jqXHR) ->
      console.log "Error: ", jqXHR

  ntrapy.indexModel = new IndexModel()
  ko.applyBindings ntrapy.indexModel

  $(document).on "click.dropdown.data-api", ntrapy.pollTree
