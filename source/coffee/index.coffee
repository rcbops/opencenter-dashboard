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

    # Temp storage for node mapping
    @wsTemp = ko.observableArray()

    # Computed wrapper for coalescing changes
    @wsItems = ko.computed =>
      @wsTemp()

    # Debounce node changes (x msec settling period)
    @wsItems.extend throttle: config?.coalesce ? 1000

    # Execution plans
    @wsPlans = ko.observableArray()

    # Flat node list, keyed by id
    @wsKeys = {}

    # Update on request success/failure
    @siteEnabled = ko.computed ->
      ntrapy.siteEnabled()

    # Debounce site disabled overlay
    @siteEnabled.extend throttle: @config?.timeout?.short ? 5000

    # Get config and grab initial set of nodes
    ntrapy.getData "/api/config", (data) =>
      # Store config
      @config = data

      # Start long-poller
      ntrapy.pollNodes (nodes, cb) => # Recursive node grabber
        pnodes = []
        resolver = (stack) =>
          id = stack.pop()
          unless id? # End of ID list
            ntrapy.updateNodes nodes: pnodes, @wsTemp, @wsKeys
            cb() if cb?
          else
            ntrapy.get "/roush/nodes/#{id}"
            , (node) -> # Success
                pnodes.push node.node
                resolver stack
            , -> false # Failure; don't retry
        resolver nodes
      , @config?.timeout?.long ? 30000

      # Load initial data
      ntrapy.getNodes "/roush/nodes/", @wsTemp, @wsKeys

    @siteActive = ntrapy.selector (data) =>
      null # TODO: Do something useful with multiple tabs
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
      ntrapy.getData "/roush/nodes/#{node.id()}/adventures", (data) ->
        node.actions (n for n in data?.adventures)

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

    # Form validator; here for scoping plan args
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

    # Sortable afterMove hook; here for scoping updateNodes args
    ko.bindingHandlers.sortable.afterMove = (options) =>
      parent = options.sourceParentNode.attributes["data-id"].value
      ntrapy.post "/roush/facts/",
        JSON.stringify
          key: "parent_id"
          value: parent
          node_id: options.item.id()
      , (data) ->
        null # TODO: Do something with success?
      , (jqXHR) =>
        console.log "Error: ", jqXHR
        ntrapy.updateNodes null, @wsTemp, @wsKeys # Remap from keys on fails

    @ # Return ourself

  popoverOptions =
    html: true
    delay: 0
    trigger: "hover"
    animation: false
    placement: ntrapy.getPopoverPlacement
    container: 'body'

  ko.bindingHandlers.popper =
    init: (el, data) ->
      opts = popoverOptions
      opts["title"] = ->
        #TODO: Figure out why this fires twice: console.log "title"
        """
        #{data()?.name?() ? "Details"}
        <ul class="backend-list">
          #{('<li><div class="item">' + backend + '</div></li>' for backend in data().facts.backends()).join('')}
        </ul>
        """
      opts["content"] = ->
        """
        <dl class="node-data">
          <dt>ID</dt>
          <dd>#{data().id()}</dd>
          <dt>Status</dt>
          <dd>#{data().status()}</dd>
          <dt>Adventure</dt>
          <dd>#{data().adventure_id() ? 'idle'}</dd>
          <dt>Task</dt>
          <dd>#{data().task_id() ? 'idle'}</dd>
        </dl>
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

  ko.applyBindings new IndexModel()
