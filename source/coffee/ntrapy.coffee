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

# AJAX wrapper which auto-retries on error
ntrapy.ajax = (type, url, data, success, error, timeout, statusCode) ->
  req = -> $.ajax
    type: type
    url: url
    data: data
    success: (data) ->
      ntrapy.siteEnabled true
      success data if success?
    error: (jqXHR, textStatus, errorThrown) =>
      retry = error jqXHR, textStatus, errorThrown if error?
      ntrapy.siteEnabled false if retry isnt false # Don't disable on repolls and such
      setTimeout req, 1000 if retry isnt false # Retry after 1000msec
    statusCode: statusCode
    dataType: "json"
    contentType: "application/json; charset=utf-8"
    timeout: timeout
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

# Use the mapping plugin on a JS object, optional mapping mapping (yo dawg), wrap for array
ntrapy.mapData = (data, pin, map={}, wrap=true) ->
  data = [data] if wrap?
  ko.mapping.fromJS data, map, pin

# Get and map data, f'reals
ntrapy.getMappedData = (url, pin, map={}, wrap=true) ->
  ntrapy.getData url, (data) -> ntrapy.mapData(data, pin, map, wrap)

# Parse node array into a flat, keyed boject, injecting children for traversal
ntrapy.parseNodes = (data, pin, keyed={}) ->
  unless data?.nodes? then {} # Bail if data is unexpected

  root = {} # We might not find a root; make sure it's empty each call

  # Index node list by ID, merging/updating if keyed was provided
  for node in data.nodes
    nid = node.id
    if keyed[nid]? # Updating existing node?
      pid = keyed[nid].facts?.parent_id # Grab current parent
      if pid? and pid isnt node.facts?.parent_id # If new parent is different
        delete keyed[pid].children[nid] # Remove node from old parent's children

    # Stub if missing
    node.actions ?= []
    node.status ?= "disabled_state"
    node.dragDisabled ?= false
    node.children ?= {}
    node.facts ?= {}
    node.facts.backends ?= []
    keyed[nid] = node # Add/update node

  # Build child arrays
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

  # Fill other properties
  for id of keyed
    node = keyed[id]
    if node.task_id?
      node.status = "warning_state"
      node.dragDisabled = true
    else
      node.status = "disabled_state"
      node.dragDisabled = false
    node.agents = (v for k,v of node.children when "agent" in v.facts.backends)
    node.containers = (v for k,v of node.children when "container" in v.facts.backends)

  pin keyed if pin? # Update pin with keyed
  root # Return root for mapping

# Process nodes and map to pin
ntrapy.updateNodes = (data, pin, keys) ->
  ntrapy.mapData ntrapy.parseNodes(data, pin, keys), pin

# Get and process nodes from url
ntrapy.getNodes = (url, pin, keys) ->
  ntrapy.getData url, (data) ->
    ntrapy.updateNodes data, pin, keys

# Poll for node changes and do the right things on changes
ntrapy.pollNodes = (cb, timeout) =>
  repoll = (trans) ->
    if trans? # Have transaction data?
      sKey = trans.session_key
      txID = trans.txid
      poll "/roush/nodes/updates/#{sKey}/#{txID}?poll" # Build URL
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
            false # Don't retry since we updated the URL
    , timeout

  repoll() # DO EET
