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

    # Execution plans
    @wsPlans = ko.observableArray()

    # Flat node list, keyed by id
    @wsKeys = {}

    # Update on request success/failure
    @siteEnabled = ko.computed ->
      unless ntrapy.siteEnabled()
        ntrapy.showModal "#indexNoConnectionModal"
      else
        ntrapy.hideModal "#indexNoConnectionModal"

    # Get config and grab initial set of nodes
    ntrapy.getData "/api/config", (data) =>
      # Store config
      @config = data

      # Debounce node changes (x msec settling period)
      @wsItems.extend throttle: @config?.throttle ? 1000

      # Debounce site disabled overlay
      @siteEnabled.extend throttle: @config?.timeout?.short ? 1000

      # Start long-poller
      ntrapy.pollNodes (nodes, cb) => # Recursive node grabber
        pnodes = []
        resolver = (stack) =>
          id = stack.pop()
          unless id? # End of ID list
            ntrapy.updateNodes nodes: pnodes, @wsTemp, @wsKeys
            cb() if cb?
          else
            ntrapy.getData "/roush/nodes/#{id}", (node) ->
              pnodes.push node.node
              resolver stack
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
            ntrapy.showModal "#indexInputModal"
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
          ntrapy.hideModal "#indexInputModal"
        , (jqXHR, textStatus, errorThrown) ->
          ntrapy.hideModal "#indexInputModal"
          console.log "Error (#{jqXHR.status}): #{errorThrown}"

    # Multi-step form controls; here for manipulating form controls based on form's page
    $("#indexInputModal").on "shown", (e) ->
      console.log "show modal indexInputModal"
      ntrapy.drawStepProgress()

    # Sortable afterMove hook; here for scoping updateNodes args
    ko.bindingHandlers.sortable.afterMove = (options) =>
      ntrapy.setBusy options.item # Set busy immediately on drop
      parent = options.sourceParentNode.attributes["data-id"].value
      ntrapy.post "/roush/facts/",
        JSON.stringify
          key: "parent_id"
          value: parent
          node_id: options.item.id()
      , (data) ->
        null # TODO: Do something with success?
      , (jqXHR, textStatus, errorThrown) =>
        console.log "Error: (#{jqXHR.status}): #{errorThrown}"
        ntrapy.updateNodes null, @wsTemp, @wsKeys # Remap from keys on fails

    # In case we don't get an update for a while, make sure we at least periodically update node statuses
    setInterval(ntrapy.updateNodes, 90000, null, @wsTemp, @wsKeys)

    @ # Return ourself

  ko.bindingHandlers.popper =
    init: (el, data) ->
      $(el).hover (event) ->
        id = data().id()
        obj = ntrapy.indexModel.wsKeys[id]
        ntrapy.killPopovers()
        if event.type is "mouseenter"
          obj.hovered = true
          ntrapy.updatePopover this, obj, true
        else
          obj.hovered = false
          ntrapy.killPopovers()

  ko.bindingHandlers.sortable.options =
    handle: ".btn"
    cancel: ".dragDisable"
    opacity: 0.35
    tolerance: "pointer"
    start: (event, ui) ->
      $("[data-bind~='popper']").popover "disable"
      ntrapy.killPopovers()
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
      ntrapy.makeBasicAuth user.val(), pass.val()
      throb.show()
      $.ajax # Test the auth
        url: "/roush/"
        headers: ntrapy.authHeader
        success: ->
          ntrapy.loggingIn = false # Done logging in
          resetForm()
          form.find('.alert').hide()
          ntrapy.hideModal "#indexLoginModal"
        error: ->
          resetForm()
          form.find('.alert').show()
          user.focus()

  ntrapy.indexModel = new IndexModel()
  ko.applyBindings ntrapy.indexModel
