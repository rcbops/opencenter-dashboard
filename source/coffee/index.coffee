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

      parseChildren = (node) ->
        node.agents = (v for k,v of node?.children when "agent" in v.facts.backends)
        node.containers = (v for k,v of node?.children  when "container" in v.facts.backends)

      # Index node list by ID, merging/updating if keyed was provided
      for node in data.nodes
        nid = node.id
        if keyed[nid]? # Updating existing node?
          pid = keyed[nid].facts?.parent_id # Grab current parent
          if pid? and pid isnt node.facts?.parent_id # If new parent is different
            delete keyed[pid].children[nid] # Remove node from old parent's children

        # Stub if missing
        node.actions ?= []
        node.status ?= "unknown"
        node.children ?= {}
        keyed[nid] = node # Add/update node

      # Step through IDs
      for id of keyed
        node = keyed[id]
        pid = node.facts?.parent_id
        if pid? # Has parent ID?
          pnode = keyed?[pid]
          if pnode? # Parent exists?
            pnode.children[id] = node # Add to parent's children
          else # We're an orphan (broken data or from previous merge)
            delete keyed[id] # No mercy for orphans!
        else if node.name is "workspace" # Mebbe root node?
          root = node # Point at it
        else # Invalid root node!
          delete keyed[id] # Pew Pew!

      for id of keyed
        parseChildren keyed[id]

      pin keyed if pin? # Update pin with keyed
      children: root # Return in format appropriate for mapping

    @updateNodes = (data, pin, keys) =>
      @mapData @parseNodes(data, pin, keys), pin

    @getNodes = (url, pin, keys) =>
      @getData url, (data) =>
        @updateNodes data, pin, keys

    @wsTemp = ko.observableArray()
    @wsItems = ko.computed(=>
      @wsTemp()?[0]?.children ? []).extend throttle: 100 # Coalesce node changes

    @wsPlans = ko.observableArray()
    @wsKeys = {}

    @poll = (url, cb, timeout=@config?.timeout?.long ? 30000) =>
      rePoll = (throttle=false) =>
        setTimeout (=> @poll "/roush/nodes/updates/#{@sKey}/#{@txID}?poll", cb, timeout), if throttle then 1000 else 1

      updateTransaction = (trans, cb) =>
        unless trans?
          @getData "/roush/updates", (pass) =>
            updateTransaction pass?.transaction
            cb() if cb?
        else
          @sKey = trans.session_key
          @txID = trans.txid

      unless @sKey? and @txID?
        updateTransaction null, -> rePoll true
      else
        $.ajax
          url: url
          success: (data) ->
            cb data.nodes
            updateTransaction data.transaction
            rePoll()
          error: (jqXHR, textStatus, errorThrown) ->
            switch jqXHR.status
              when 410 # Gone, cycle transaction
                updateTransaction null, -> rePoll()
              when 502 # Bad gateway; proxy failure
                rePoll true
              else # Other errors
                if textStatus is "timeout"
                  rePoll()
                else
                  console.log "Error (#{jqXHR.status}): #{textStatus} - #{errorThrown}"
                  rePoll true
          dataType: "json"
          timeout: timeout

    # Get config and grab initial set of nodes
    @getData "/api/config", (data) =>
      # Store config
      @config = data

      # Start long-poller
      @poll "/roush/nodes/updates/#{@sKey}/#{@txID}?poll", (nodes, cb) =>
        pnodes = []
        resolver = (stack) =>
          id = stack.pop()
          unless id? # End of ID list
            @updateNodes nodes: pnodes, @wsTemp, @wsKeys
            cb() if cb?
          else
            @getData "/roush/nodes/#{id}", (node) =>
              pnodes.push node.node
              resolver stack
        resolver nodes

      # Load initial data
      @getNodes "/roush/nodes/", @wsTemp, @wsKeys

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
            console.log "Error (#{jqXHR.status}): errorThrown"

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
          console.log "Error (#{jqXHR.status}): errorThrown"

    @ # Return ourself

  popoverOptions =
    html: true
    delay: 0
    trigger: "hover"
    animation: true
    placement: ntrapy.getPopoverPlacement

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
      # TODO: Do something on sort stop?

  ko.bindingHandlers.sortable.afterMove = (options) ->
    parent = options.sourceParentNode.attributes["data-id"].value
    ntrapy.post "/roush/facts/",
      JSON.stringify
        key: "parent_id"
        value: parent
        node_id: options.item.id()
    , (data) ->
      null # TODO: Do something with success?
    , (jqXHR) ->
      console.log "Error: ", jqXHR

  ntrapy.indexModel = new IndexModel()
  ko.applyBindings ntrapy.indexModel
