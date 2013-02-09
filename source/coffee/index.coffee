# Grab namespace
ntrapy = exports?.ntrapy ? @ntrapy

$ ->
  IndexModel = ->
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

    # Basic JSON grabber
    @getData = (url, cb) ->
      $.getJSON url, (data) ->
        cb data if cb?

    # Use the mapping plugin on a JS object, optional mapping mapping (yo dawg), wrap for array
    @mapData = (data, pin, map={}, wrap=true) ->
      data = [data] if wrap?
      ko.mapping.fromJS data, map, pin

    # Get and map data, f'reals
    @getMappedData = (url, pin, map={}, wrap=true) =>
      @getData url, (data) => @mapData(data, pin, map, wrap)

    # Parse a flat node list, injecting children arrays for traversal
    @parseNodes = (data, pin, keyed={}) ->
      root = {}

      console.log "Keyed: ", keyed

      # Index node list by ID, merging/updating if keyed was provided
      for node in data.nodes
        console.log "Node: ", node
        keyed[node.id] = node

      # Step through IDs
      for id of keyed
        console.log "Id: ", id
        node = keyed[id]
        pid = node.facts?.parent_id
        if pid? # Has parent ID?
          pnode = keyed?[pid]
          if pnode? # Parent exists?
            pnode.children ?= [] # Initialize if first child
            pnode.children.push node # Add to parent's children
          else # We're an orphan (broken data or from previous merge)
            console.log "Deleting orphan: ", keyed[id], node
            delete keyed[id] # No mercy for orphans!
        else if node.name is "workspace" # Mebbe root node?
          root = node # Point at it
        else # Invalid root node!
          console.log "Deleting invalid root: ", id, node
          delete keyed[id] # Pew Pew!

      pin keyed if pin? # Update pin with keyed
      children: root # Return in format appropriate for mapping

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
        status: "unknown"
      , {}, ko.mapping.fromJS @node, mapping

    @updateNodes = (data, pin, keys) =>
      @mapData @parseNodes(data, null, keys), pin, mapping

    @getNodes = (url, pin, keys) =>
      @getData url, (data) =>
        @updateNodes data, pin, keys

    @wsTemp = ko.observableArray()
    @wsItems = ko.computed(=>
      @wsTemp()?[0]?.children ? []).extend throttle: 200 # Coalesce node changes

    @wsPlans = ko.observableArray()
    @wsKeys = ko.observable()

    @poll = (url, cb, timeout=@config?.timeout?.long) =>
      rePoll = (data) =>
        if data?
          @sKey = data.transaction.session_key
          @txID = data.transaction.txid
          console.log "Updating transaction: ", @sKey, @txID
        # Restart long-poller for new transaction
        setTimeout (=> @poll "/roush/nodes/updates/#{@sKey}/#{@txID}?poll", cb, timeout), 1

      $.ajax
        url: url
        success: (data) =>
          cb data
          rePoll data
        error: (jqXHR, textStatus, errorThrown) =>
          switch jqXHR.status
            when 410 # Gone, cycle txID
              @getData "/roush/updates", (data) =>
                rePoll data
            when 0 # Timeout
              console.log "Retrying"
              rePoll()
            else # Other errors
              console.log "Error (#{jqXHR.status}): #{errorThrown}"
              setTimeout (=> @poll url, cb, timeout), 1000 # Throttle retry
        dataType: "json"
        timeout: timeout ? 30000

    # Get config and grab initial set of nodes
    @getData "/api/config", (data) =>
      # Store config
      @config = data

      @getData "/roush/updates", (data) =>
        @sKey = data?.transaction?.session_key
        @txID = data?.transaction?.txid
        console.log "Got transaction: ", @sKey, @txID
        # Start long-poller
        @poll "/roush/nodes/updates/#{@sKey}/#{@txID}?poll", (data) =>
          console.log "Got update: ", data
          setTimeout @updateNodes(data, @wsKeys, @wsTemp), 1000

        # Load initial data, and poll every config.interval ms
        @getNodes "/roush/nodes/", @wsKeys, @wsTemp

    @siteActive = ntrapy.selector (data) =>
      null # TODO:
      #switch data.name
      #  when "Workspace"
      #    @getMappedData "/roush/nodes/1/tree", @wsTemp, mapping
    , @siteNav()[0] # Set to first by default

    # Template accessor that avoids data-loading race
    @getTemplate = ko.computed =>
      @siteActive()?.template ? {} # TODO: Needs .template?() if @siteNav is mapped

    # Index template sub-accessor. TODO: unstub for zero-state template progression
    @getIndexTemplate = ko.computed =>
      name: "indexItemTemplate"
      foreach: @wsItems

    # Plan flattener. TODO: Stop flattening plans into a single object to handle multi-step plans intelligently
    @getPlans = ko.computed =>
      if not @wsPlans()?.plan?.length
        return null

      ret = []
      ret.push (ntrapy.toArray n?.args)... for n in @wsPlans()?.plan
      ret

    @getActions = (node) =>
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
      focusCleanup: true
      highlight: (element) ->
        $(element).closest('.control-group').removeClass('success').addClass('error')
      success: (element) ->
        $(element).closest('.control-group').removeClass('error').addClass('success')
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
    stop: (event, ui) ->
      null

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
