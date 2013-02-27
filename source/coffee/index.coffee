# Grab namespace
dashboard = exports?.dashboard ? @dashboard

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

    # Execution plans
    @wsPlans = ko.observableArray()

    # Flat node list, keyed by id
    @wsKeys = {}

    # Update on request success/failure
    @siteEnabled = ko.computed ->
      unless dashboard.siteEnabled()
        dashboard.showModal "#indexNoConnectionModal"
      else
        dashboard.hideModal "#indexNoConnectionModal"

    # Get config and grab initial set of nodes
    dashboard.getData "/api/config", (data) =>
      # Store config
      @config = data

      # Debounce node changes (x msec settling period)
      @wsItems.extend throttle: @config?.throttle ? 1000

      # Debounce site disabled overlay
      @siteEnabled.extend throttle: @config?.timeout?.short ? 1000

      # Start long-poller
      dashboard.pollNodes (nodes, cb) => # Recursive node grabber
        pnodes = []
        resolver = (stack) =>
          id = stack.pop()
          unless id? # End of ID list
            dashboard.updateNodes nodes: pnodes, @wsTemp, @wsKeys
            cb() if cb?
          else
            dashboard.getData "/octr/nodes/#{id}", (node) ->
              pnodes.push node.node
              resolver stack
        resolver nodes
      , @config?.timeout?.long ? 30000

      # Load initial data
      dashboard.getNodes "/octr/nodes/", @wsTemp, @wsKeys

    @siteActive = dashboard.selector (data) =>
      null # TODO: Do something useful with multiple tabs
      #switch data.name
      #  when "Workspace"
      #    @getMappedData "/octr/nodes/1/tree", @wsTemp, mapping
    , @siteNav()[0] # Set to first by default

    # Template accessor that avoids data-loading race
    @getTemplate = ko.computed =>
      @siteActive()?.template ? {} # TODO: Needs .template?() if @siteNav is mapped

    # Index template sub-accessor. TODO: unstub for zero-state template progression
    @getIndexTemplate = ko.computed =>
      name: "indexItemTemplate"
      foreach: @wsItems

    # Plan flattener
    @getPlans = ko.computed =>
      if not @wsPlans()?.plan?.length
        return null

      ret = []
      #ret.push (dashboard.toArray n?.args)... for n in @wsPlans()?.plan
      for plan in @wsPlans()?.plan
        step = {}
        step.name = '' #TODO: Possibly create a name for each step.
        step.args = dashboard.toArray plan?.args
        # Fixup missing/empty friendly names
        for arg,index in step.args
          unless arg.value?.friendly? and !!arg.value.friendly
            step.args[index].value.friendly = step.args[index].key
        if step.args.length
          ret.push (step)
      ret

    @getActions = (node) =>
      dashboard.getData "/octr/nodes/#{node.id()}/adventures", (data) ->
        node.dash.actions (n for n in data?.adventures)

    @doAction = (object, action) =>
      dashboard.post "/octr/adventures/#{action.id}/execute",
        JSON.stringify node: object.id()
      , (data) -> # success handler
        null #TODO: Use success for something
      , (jqXHR, textStatus, errorThrown) => # error handler
        switch jqXHR.status
          when 409 # Need more data
            @wsPlans JSON.parse jqXHR.responseText
            @wsPlans().node = object.id()
            dashboard.showModal "#indexInputModal"
          else
            console.log "Error (#{jqXHR.status}): #{errorThrown}"

    # Input form validator; here for scoping plan args
    $('#inputForm').validate
      focusCleanup: true
      highlight: (element) ->
        $(element).closest('.control-group').removeClass('success').addClass('error')
      success: (element) ->
        $(element).closest('.control-group').removeClass('error').addClass('success')
      submitHandler: (form) =>
        $(form).find('.control-group').each (index, element) =>
          key = $(element).find('label').first().attr('for')
          val = $(element).find('input').val()
          for plan in @wsPlans().plan
            if plan?.args?[key]?
              plan.args[key].value = val
        dashboard.post "/octr/plan/",
          JSON.stringify
            node: @wsPlans().node
            plan: @wsPlans().plan
        , (data) ->
          dashboard.hideModal "#indexInputModal"
        , (jqXHR, textStatus, errorThrown) ->
          dashboard.hideModal "#indexInputModal"
          console.log "Error (#{jqXHR.status}): #{errorThrown}"

    # Multi-step form controls; here for manipulating form controls based on form's page
    #$("#indexInputModal").on "show", (e) ->
    #  dashboard.drawStepProgress()

    # Sortable afterMove hook; here for scoping updateNodes args
    ko.bindingHandlers.sortable.afterMove = (options) =>
      dashboard.setBusy options.item # Set busy immediately on drop
      parent = options.sourceParentNode.attributes["data-id"].value
      dashboard.post "/octr/facts/",
        JSON.stringify
          key: "parent_id"
          value: parent
          node_id: options.item.id()
      , (data) ->
        null # TODO: Do something with success?
      , (jqXHR, textStatus, errorThrown) =>
        console.log "Error: (#{jqXHR.status}): #{errorThrown}"
        dashboard.updateNodes null, @wsTemp, @wsKeys # Remap from keys on fails

    # In case we don't get an update for a while, make sure we at least periodically update node statuses
    setInterval(dashboard.updateNodes, 90000, null, @wsTemp, @wsKeys)

    @ # Return ourself

  ko.bindingHandlers.popper =
    init: (el, data) ->
      $(el).hover (event) ->
        id = data().id()
        obj = dashboard.indexModel.wsKeys[id]
        dashboard.killPopovers()
        if event.type is "mouseenter"
          obj.hovered = true
          dashboard.updatePopover this, obj, true
        else
          obj.hovered = false
          dashboard.killPopovers()

  ko.bindingHandlers.sortable.options =
    handle: ".btn"
    cancel: ".dragDisable"
    opacity: 0.35
    tolerance: "pointer"
    start: (event, ui) ->
      $("[data-bind~='popper']").popover "disable"
      dashboard.killPopovers()
    stop: (event, ui) ->
      null
      # TODO: Do something on sort stop?

  # Login form validator
  $('#loginForm').validate
    #focusCleanup: true
    highlight: (element) ->
      $(element).closest('.control-group').removeClass('success').addClass('error')
    success: (element) ->
      $(element).closest('.control-group').removeClass('error').addClass('success')
    submitHandler: (form) ->
      form = $(form)
      group = form.find('.control-group')
      user = group.first().find('input')
      pass = group.next().find('input')
      throb = form.find('.form-throb')
      resetForm = ->
        throb.hide()
        group.find('input').val ""
        group.removeClass ['error', 'success']
        group.find('.controls label').remove()
      dashboard.makeBasicAuth user.val(), pass.val()
      throb.show()
      $.ajax # Test the auth
        url: "/octr/"
        headers: dashboard.authHeader
        success: ->
          dashboard.loggingIn = false # Done logging in
          resetForm()
          form.find('.alert').hide()
          dashboard.hideModal "#indexLoginModal"
        error: ->
          resetForm()
          form.find('.alert').show()
          user.focus()

  ko.bindingHandlers.tipper =
    init: (el, data) ->
      opts =
        title: data().description
        trigger: "hover"
        container: "#indexInputModal"
        animation: false
      $(el).tooltip opts

  ko.bindingHandlers.dropper =
    update: (el, data) ->
      if ko.utils.unwrapObservable data()
        $(el).removeClass("ko_container").removeClass("ui-sortable")
      else
        $(el).addClass("ko_container").addClass("ui-sortable")

  # Custom binding provider with error handling
  ErrorHandlingBindingProvider = ->
    original = new ko.bindingProvider()

    # Determine if an element has any bindings
    @nodeHasBindings = original.nodeHasBindings

    # Return the bindings given a node and the bindingContext
    @getBindings = (node, bindingContext) ->
      try
        original.getBindings node, bindingContext
      catch e
        console.log "Error in binding: " + e.message, node
        window.location = "/" # Reload page for now
    @

  ko.bindingProvider.instance = new ErrorHandlingBindingProvider()

  dashboard.indexModel = new IndexModel()
  ko.applyBindings dashboard.indexModel
