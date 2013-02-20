# Create and store namespace
ntrapy = exports?.ntrapy ? @ntrapy = {}

ntrapy.statusColor = (status) ->
  switch status
    when "unprovisioned"
      return "#3A87AD"
    when "good"
      return "#468847"
    when "alert"
      return "#F89406"
    when "error"
      return "#B94A48"

ntrapy.statusLabel = (status) ->
  switch status
    when "unprovisioned"
      return "label-info"
    when "good"
      return "label-success"
    when "alert"
      return "label-warning"
    when "error"
      return "label-important"

ntrapy.statusButton = (status) ->
  switch status
    when "unprovisioned"
      return "processing_state"
    when "good"
      return "ok_state"
    when "alert"
      return "warning_state"
    when "error"
      return "error_state"
    when "unknown"
      return "disabled_state"

ntrapy.selector = (cb, def) ->
  selected = ko.observable def ? {} unless selected?
  cb def if cb? and def?
  ko.computed
    read: ->
      selected()
    write: (data) ->
      selected data
      cb data if cb?

# Object -> Array mapper
ntrapy.toArray = (obj) ->
  array = []
  for prop of obj
    if obj.hasOwnProperty(prop)
      array.push
        key: prop
        value: obj[prop]

  array # Return mapped array

ntrapy.getPopoverPlacement = (tip, element) ->
  isWithinBounds = (elementPosition) ->
    boundTop < elementPosition.top and boundLeft < elementPosition.left and boundRight > (elementPosition.left + actualWidth) and boundBottom > (elementPosition.top + actualHeight)
  $element = $ element
  pos = $.extend {}, $element.offset(),
    width: element.offsetWidth
    height: element.offsetHeight
  actualWidth = 283
  actualHeight = 117
  boundTop = $(document).scrollTop()
  boundLeft = $(document).scrollLeft()
  boundRight = boundLeft + $(window).width()
  boundBottom = boundTop + $(window).height()
  elementAbove =
    top: pos.top - actualHeight
    left: pos.left + pos.width / 2 - actualWidth / 2

  elementBelow =
    top: pos.top + pos.height
    left: pos.left + pos.width / 2 - actualWidth / 2

  elementLeft =
    top: pos.top + pos.height / 2 - actualHeight / 2
    left: pos.left - actualWidth

  elementRight =
    top: pos.top + pos.height / 2 - actualHeight / 2
    left: pos.left + pos.width

  above = isWithinBounds elementAbove
  below = isWithinBounds elementBelow
  left = isWithinBounds elementLeft
  right = isWithinBounds elementRight
  (if above then "top" else (if below then "bottom" else (if left then "left" else (if right then "right" else "right"))))

# Keep track of AJAX success/failure
ntrapy.siteEnabled = ko.observable true

# Fill in auth header with user/pass
ntrapy.makeBasicAuth = (user, pass) ->
  ntrapy.authUser user
  token = "#{user}:#{pass}"
  ntrapy.authHeader = Authorization: "Basic #{btoa token}"

# Auth bits
ntrapy.authHeader = {}
ntrapy.authUser = ko.observable ""
ntrapy.authCheck = ko.computed ->
  if ntrapy.authUser() isnt "" then true else false
ntrapy.authLogout = ->
  # Clear out all the things
  model = ntrapy.indexModel
  ntrapy.authHeader = {}
  ntrapy.authUser ""
  model.wsKeys = {}
  model.wsTemp []
  # Try grabbing new nodes; will trigger login form if needed
  ntrapy.getNodes "/roush/nodes/", model.wsTemp, model.wsKeys

# Guard to spin requests while logging in
ntrapy.loggingIn = false

ntrapy.drawStepProgress = ->
  $form = $("form#inputForm")
  $multiStepForm = $form.find(".carousel")
  $formBody = $form.find(".modal-body")
  $formControls = $form.find(".modal-footer")

  if $multiStepForm.length and $formControls.length
    $back = $formControls.find(".back")
    $next = $formControls.find(".next")
    $submit = $formControls.find(".submit")
    slideCount = $multiStepForm.find('.carousel-inner .item').length

    if slideCount is 1
      $back.hide()
      $next.hide()
      $submit.show()
    else
      str = ""
      count = 0
      percentWidth = 100 / slideCount

      while count < slideCount
        str += "<div id=\"progress-bar-" + (count + 1) + "\" class=\"progress-bar\" style=\"width:" + percentWidth + "%;\"></div>"
        count++

      $progressMeter = $("#progress-meter")
      $progressMeter.remove()  if $progressMeter.length
      $progressMeter = $('<div id="progress-meter">' + str + '</div>').prependTo($formBody)
      $back.attr "disabled", true
      $submit.hide()

    $multiStepForm.on "slid", "", ->
      $this = $(this)
      $progressMeter.find(".progress-bar").removeClass "filled"
      $activeProgressBars = $progressMeter.find('.progress-bar').slice 0, parseInt $(".carousel-inner .item.active").index() + 1, 10
      $activeProgressBars.addClass "filled"
      $formControls.find("button").show().removeAttr "disabled"
      if $this.find(".carousel-inner .item:first").hasClass("active")
        $back.attr "disabled", true
        $submit.hide()
      else if $this.find(".carousel-inner .item:last").hasClass("active")
        $next.hide()
        $submit.show()
      else
        $submit.hide()

# Modal helpers
ntrapy.showModal = (id) ->
  $(".modal").not(id).modal "hide"
  ntrapy.drawStepProgress() if id is '#indexInputModal'
  $(id).modal("show").on "shown", ->
    $(id).find("input").first().focus()
ntrapy.hideModal = (id) ->
  $(id).modal "hide"

# AJAX wrapper which auto-retries on error
ntrapy.ajax = (type, url, data, success, error, timeout, statusCode) ->
  req = ->
    if ntrapy.loggingIn # If logging in
      setTimeout req, 1000 # Spin request
    else
      $.ajax
        type: type
        url: url
        data: data
        headers: ntrapy.authHeader # Add basic auth
        success: (data) ->
          ntrapy.siteEnabled true # Enable site
          ntrapy.hideModal "#indexNoConnectionModal" # Hide immediately
          req.backoff = 250 # Reset on success
          success data if success?
        error: (jqXHR, textStatus, errorThrown) ->
          retry = error jqXHR, textStatus, errorThrown if error?
          if jqXHR.status is 401 # Unauthorized!
            ntrapy.loggingIn = true # Block other requests
            ntrapy.showModal "#indexLoginModal" # Gimmeh logins
            setTimeout req, 1000 # Requeue this one
          else if retry is true and type is "GET" # Opted in and not a POST
            setTimeout req, req.backoff # Retry with incremental backoff
            unless jqXHR.status is 0 # Didn't timeout
              ntrapy.siteEnabled false # Don't disable on repolls and such
              req.backoff *= 2 if req.backoff < 32000 # Do eet
        statusCode: statusCode
        dataType: "json"
        contentType: "application/json; charset=utf-8"
        timeout: timeout
  req.backoff = 250 # Start at 0.25 sec
  req()

# Request wrappers
ntrapy.get = (url, success, error, statusCode) ->
  ntrapy.ajax "GET", url, null, success, error, statusCode

ntrapy.post = (url, data, success, error, statusCode) ->
  ntrapy.ajax "POST", url, data, success, error, statusCode

# Basic JS/JSON grabber
ntrapy.getData = (url, cb) ->
  ntrapy.get url, (data) ->
    cb data if cb?
  , -> true # Retry

# Use the mapping plugin on a JS object, optional mapping mapping (yo dawg), wrap for array
ntrapy.mapData = (data, pin, map={}, wrap=true) ->
  data = [data] if wrap?
  ko.mapping.fromJS data, map, pin

# Get and map data, f'reals
ntrapy.getMappedData = (url, pin, map={}, wrap=true) ->
  ntrapy.get url, (data) ->
    ntrapy.mapData data, pin, map, wrap
  , -> true # Retry

# Parse node array into a flat, keyed boject, injecting children for traversal
ntrapy.parseNodes = (data, keyed={}) ->
  root = {} # We might not find a root; make sure it's empty each call

  # Index node list by ID, merging/updating if keyed was provided
  for node in data?.nodes ? []
    nid = node.id
    if keyed[nid]? # Updating existing node?
      pid = keyed[nid].facts?.parent_id # Grab current parent
      if pid? and pid isnt node.facts?.parent_id # If new parent is different
        ntrapy.killPopovers() # We're moving so kill popovers
        keyed[nid].hovered = false # And cancel hovers
        if node.task_id?
          #console.log "Pending: #{node.task_id}: #{keyed[nid].facts.parent_id} -> #{node.facts.parent_id}"
          node.facts.parent_id = keyed[nid].facts.parent_id # Ignore parent changes until tasks complete
        else
          console.log "Deleting: #{node.task_id}: #{keyed[nid].facts.parent_id} -> #{node.facts.parent_id}"
          delete keyed[pid].children[nid] # Remove node from old parent's children

    # Stub if missing
    node.actions ?= []
    node.statusClass ?= ko.observable "disabled_state"
    node.statusText ?= ko.observable "Unknown"
    node.dragDisabled ?= ko.observable false
    node.children ?= {}
    node.facts ?= {}
    node.facts.backends ?= []
    node.hovered ?= keyed[nid]?.hovered ? false
    keyed[nid] = node # Add/update node

  # Build child arrays
  for id of keyed
    node = keyed[id]
    pid = node.facts?.parent_id
    if pid? # Has parent ID?
      #console.log "Node: #{id}, Parent: #{pid}"
      pnode = keyed?[pid]
      if pnode? # Parent exists?
        pnode.children[id] = node # Add to parent's children
      else # We're an orphan (broken data or from previous merge)
        delete keyed[id] # No mercy for orphans!
    else if node.name is "workspace" # Mebbe root node?
      root = node # Point at it
    else # Invalid root node!
      delete keyed[id] # Pew Pew!

  # Node staleness checker
  stale = (node) ->
    if node?.attrs?.last_checkin? # Have we checked in at all?
      if Math.abs(+node.attrs.last_checkin - +ntrapy.txID) > 90 then true # Hasn't checked in for 3 cycles
      else false
    else false

  # Fill other properties
  for id of keyed
    node = keyed[id]
    if node?.attrs?.last_task is "failed"
      ntrapy.setError node
    else if stale node or node?.attrs?.last_task is "rollback"
      ntrapy.setWarning node
    else if node.task_id?
      ntrapy.setBusy node
    else
      ntrapy.setGood node

    if node.hovered
      ntrapy.updatePopover $("[data-bind~='popper'],[data-id='#{id}']"), node, true # Update matching popover

    node.agents = (v for k,v of node.children when "agent" in v.facts.backends)
    node.containers = (v for k,v of node.children when "container" in v.facts.backends)

  root # Return root for mapping

ntrapy.setError = (node) ->
  node.statusClass "error_state"
  node.statusText "Error"
  node.dragDisabled false

ntrapy.setWarning = (node) ->
  node.statusClass "processing_state"
  node.statusText "Warning"
  node.dragDisabled false

ntrapy.setBusy = (node) ->
  node.statusClass "warning_state"
  node.statusText "Busy"
  node.dragDisabled true

ntrapy.setGood = (node) ->
  node.statusClass "ok_state"
  node.statusText "Good"
  node.dragDisabled false

# Process nodes and map to pin
ntrapy.updateNodes = (data, pin, keys) ->
  ntrapy.mapData ntrapy.parseNodes(data, keys), pin

# Get and process nodes from url
ntrapy.getNodes = (url, pin, keys) ->
  ntrapy.get url, (data) ->
    ntrapy.updateNodes data, pin, keys
  , -> true # Retry

# Poll for node changes and do the right things on changes
ntrapy.pollNodes = (cb, timeout) =>
  repoll = (trans) ->
    if trans? # Have transaction data?
      ntrapy.sKey = trans.session_key
      ntrapy.txID = trans.txid
      poll "/roush/nodes/updates/#{ntrapy.sKey}/#{ntrapy.txID}?poll" # Build URL
    else # Get you some
      ntrapy.getData "/roush/updates", (pass) ->
        repoll pass?.transaction # Push it back through

  poll = (url) ->
    ntrapy.get url
    , (data) -> # Success
        cb data?.nodes if cb?
        repoll data?.transaction
    , (jqXHR, textStatus, errorThrown) -> # Error; can retry after this cb
        switch jqXHR.status
          when 410 # Gone
            repoll() # Cycle transaction
          else
            true # Retry otherwise
    , timeout

  repoll() # DO EET

ntrapy.popoverOptions =
  html: true
  delay: 0
  trigger: "manual"
  animation: false
  placement: ntrapy.getPopoverPlacement
  container: 'body'

ntrapy.killPopovers = ->
  $("[data-bind~='popper']").popover "hide"
  $(".popover").remove()

ntrapy.updatePopover = (el, obj, show=false) ->
  opts = ntrapy.popoverOptions
  doIt = (task) ->
    opts["title"] =
      #TODO: Figure out why this fires twice: console.log "title"
      """
      #{obj.name? ? "Details"}
      <ul class="backend-list tags">
          #{('<li><div class="item">' + backend + '</div></li>' for backend in obj.facts.backends).join('')}
      </ul>
      """
    opts["content"] =
      """
      <dl class="node-data">
        <dt>ID</dt>
        <dd>#{obj.id}</dd>
        <dt>Status</dt>
        <dd>#{obj.statusText()}</dd>
        <dt>Adventure</dt>
        <dd>#{obj.adventure_id ? 'idle'}</dd>
        <dt>Task</dt>
        <dd>#{task ? 'idle'}</dd>
        <dt>Last Task</dt>
        <dd>#{obj?.attrs?.last_task ? 'unknown'}</dd>
      </dl>
      """
    #console.log "Task: ", task
    #console.log "Status: ", obj.statusText()
    $(el).popover opts
    if show
      #console.log "Reshowing"
      ntrapy.killPopovers()
      $(el).popover "show"

  if obj?.task_id?
    ntrapy.get "/roush/tasks/#{obj.task_id}"
    , (data) -> doIt data?.task?.action
    , -> doIt()
  else
    doIt()
