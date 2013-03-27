#               OpenCenter™ is Copyright 2013 by Rackspace US, Inc.
# ###############################################################################
#
# OpenCenter is licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.  This version
# of OpenCenter includes Rackspace trademarks and logos, and in accordance with
# Section 6 of the License, the provision of commercial support services in
# conjunction with a version of OpenCenter which includes Rackspace trademarks
# and logos is prohibited.  OpenCenter source code and details are available at:
# https://github.com/rcbops/opencenter or upon written request.
#
# You may obtain a copy of the License at
# http://www.apache.org/licenses/LICENSE-2.0 and a copy, including this notice,
# is available in the LICENSE file accompanying this software.
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the License for the
# specific language governing permissions and limitations under the License.
#
# ###############################################################################

# Grab namespace
dashboard = exports?.dashboard ? @dashboard

$ ->
  IndexModel = ->
    # TODO: Map from data source
    @siteNav = ko.observableArray [
      name: "OpenCenter"
      template: "indexTemplate"
    ]

    # Track this for UI caching
    @siteLocked = ko.observable false

    # Temp storage for node mapping
    @tmpItems = ko.observableArray()
    @tmpCache = ko.observableArray()

    # Computed wrapper for coalescing changes
    @wsItems = ko.computed =>
      if @siteLocked()
        @tmpCache()
      else # Otherwise fill cache and return
        @tmpCache @tmpItems()
        @tmpItems()

    # Execution plans
    @wsPlans = ko.observableArray()

    # Flat node list, keyed by id
    @keyItems = {}

    # Current task list
    @wsTasks = ko.observableArray()

    # Flat task list, keyed by id
    @keyTasks = {}

    @getTaskCounts = ko.computed =>
      counts = {}
      for task in @wsTasks()
        status = task.dash.statusClass()
        counts[status] ?= 0
        counts[status] += 1
      for k,v of counts
        statusClass: k
        count: v

    @wsTaskTitle = ko.observable("Select a task to view its log")

    @getTaskTitle = ko.computed =>
      @wsTaskTitle()

    @wsTaskLog = ko.observable("...")

    @getTaskLog = ko.computed =>
      @wsTaskLog()

    @selectTask = (data, event) =>
      $node = $(event.target).closest(".task")
      $node.siblings().removeClass("active")
      $node.addClass("active")
      for k,v of @keyTasks
        @keyTasks[k].dash["active"] = false
      id = $node.attr("data-id")
      dash = @keyTasks[id].dash
      dash["active"] = true
      @wsTaskTitle dash.label
      @wsTaskLog "Retrieving log..."

      # Kill any pending watch requests
      dashboard.killRequests /logs\?watch/i

      # Log streaming
      dashboard.getData "/octr/tasks/#{id}/logs?watch", (data) =>
        if data?.request?
          dashboard.killRequests /logs\//i # Kill any existing log streams
          url = "/octr/tasks/#{id}/logs/#{data.request}"
          xhr = new XMLHttpRequest()
          xhr.open "GET", url
          xhr.setRequestHeader('Authorization', dashboard.authHeader.Authorization)
          xhr.onloadstart = ->
            dashboard.pendingRequests[url] = xhr # Store
          xhr.onprogress = =>
            @wsTaskLog xhr.responseText # Update log observable
            $contents = $("#logPane .pane-contents")
            $contents.scrollTop $contents.prop("scrollHeight") # Scroll to bottom
          xhr.onloadend = ->
            delete dashboard.pendingRequests[url] # Clean up
          xhr.send() # Do it!
      , -> true # Retry if fails

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
      @wsItems.extend throttle: @config?.throttle?.nodes ? 500

      # Debounce site disabled overlay
      @siteEnabled.extend throttle: @config?.throttle?.site ? 2000

      # Start long-poller
      dashboard.pollNodes (nodes, cb) => # Recursive node grabber
        pnodes = []
        resolver = (stack) =>
          id = stack.pop()
          unless id? # End of ID list
            dashboard.updateNodes nodes: pnodes, @tmpItems, @keyItems
            cb() if cb?
          else
            dashboard.getData "/octr/nodes/#{id}"
            , (node) ->
                pnodes.push node.node # Got a node, so push it
                resolver stack # Continue
            , (jqXHR) =>
                switch jqXHR.status
                  when 404
                    node = @keyItems[id]
                    unless node? # Already deleted?
                      resolver stack # Continue
                      break # Bail this thread
                    pid = node?.facts?.parent_id
                    if pid? # Have parent?
                      delete @keyItems[pid].dash.children[id] # Delete from parent's children
                    delete @keyItems[id] # Remove node
                    resolver stack # Continue
                  else true # Retry GET
                false # Don't retry GET
        resolver nodes
      , @config?.timeout?.long ? 30000

      # Start dumb poller
      dashboard.pollTasks (tasks) =>
        dashboard.updateTasks tasks, @wsTasks, @keyTasks
      , @config?.throttle?.tasks ? 2000

      # Load initial data
      dashboard.getNodes "/octr/nodes/", @tmpItems, @keyItems
      dashboard.getTasks "/octr/tasks/", @wsTasks, @keyTasks

    @siteActive = dashboard.selector (data) =>
      null # TODO: Do something useful with multiple tabs
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

    # Document clicks hide menus and bubble up here
    $(document).click => @siteLocked false

    @getActions = (node) =>
      $el = $("[data-id=#{node.id()}]")
      $place = $el.siblings(".dropdown-menu").find("#placeHolder")
      open = $el.parent().hasClass("open")
      if open # Closing menu
        @siteLocked false
      else # Opening menu
        @siteLocked true
        $place.empty() # Clear children
        $place.append("<div class='form-throb' />") # Show throbber
        dashboard.getData "/octr/nodes/#{node.id()}/adventures", (data) ->
          if data?.adventures?.length # Have adventures?
            node.dash.actions (n for n in data?.adventures)
          else # No adventures
            $place.text "No actions available" # Show sad message

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

    @toggleTaskLogPane = ->
      unless ko.utils.unwrapObservable(dashboard.displayTaskLogPane())
        dashboard.displayTaskLogPane true
      else
        dashboard.displayTaskLogPane false

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
        dashboard.updateNodes null, @tmpItems, @keyItems # Remap from keys on fails

    # In case we don't get an update for a while, make sure we at least periodically update node statuses
    setInterval(dashboard.updateNodes, 90000, null, @tmpItems, @keyItems)

    @ # Return ourself

  ko.bindingHandlers.popper =
    init: (el, data) ->
      $(el).hover (event) ->
        id = data().id()
        obj = dashboard.indexModel.keyItems[id]
        dashboard.killPopovers()
        if dashboard.indexModel.siteLocked()
          return # Don't pop when locked
        if event.type is "mouseenter"
          obj.hovered = true
          dashboard.updatePopover this, obj, true
        else
          obj.hovered = false
          dashboard.killPopovers()

  ko.bindingHandlers.sortable.options =
    handle: ".draggable"
    cancel: ".dragDisable"
    opacity: 0.35
    placeholder: "place-holder"
    start: (event, ui) ->
      $("[data-bind~='popper']").popover "disable"
      dashboard.killPopovers()
      dashboard.indexModel.siteLocked true
    stop: (event, ui) ->
      dashboard.indexModel.siteLocked false

  $.validator.addMethod "cidrType", (value, element) ->
    dot2num = (dot) ->
      d = dot.split('.')
      ((((((+d[0])*0x100)+(+d[1]))*0x100)+(+d[2]))*0x100)+(+d[3])

    num2dot = (num) ->
      ((num >> 24) & 0xff) + "." +
      ((num >> 16) & 0xff) + "." +
      ((num >> 8) & 0xff) + "." +
      (num & 0xff)

    regex = /^((?:(?:\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5])\.){3}(?:\d|[1-9]\d|1\d{2}|2[0-4]\d|25[0-5]))(?:\/(\d|[1-2]\d|3[0-2]))$/
    match = regex.exec value

    if match?
      mask = +match[2]
      num = dot2num match[1]
      masked = num2dot(num & (0xffffffff << (32-mask)))
      if masked is match[1] then true else false
    else false
  , "Validate CIDR"

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

  ko.bindingHandlers.showPane =
    init: (el, data) ->
    update: (el, data) ->
      paneHeight = $(el).height()
      footerHeight = $("#footer").height()
      #footerNotifications = $('#tasklog-toggle .pane-notifications')

      unless ko.utils.unwrapObservable(data())
        bottom = -1 * paneHeight
        fadeOpacity = 1
      else
        bottom = footerHeight
        fadeOpacity = 0

      #footerNotifications.fadeTo 300, fadeOpacity
      $(el).animate
        bottom: bottom
      , 300, ->

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
    @

  ko.bindingProvider.instance = new ErrorHandlingBindingProvider()

  dashboard.indexModel = new IndexModel()
  ko.applyBindings dashboard.indexModel
