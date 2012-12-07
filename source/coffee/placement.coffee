 $("a[rel=popover]").popover placement: (tip, element) ->
    isWithinBounds = (elementPosition) ->
      boundTop < elementPosition.top and boundLeft < elementPosition.left and boundRight > (elementPosition.left + actualWidth) and boundBottom > (elementPosition.top + actualHeight)
    $element = $(element)
    pos = $.extend({}, $element.offset(),
      width: element.offsetWidth
      height: element.offsetHeight
    )
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

    above = isWithinBounds(elementAbove)
    below = isWithinBounds(elementBelow)
    left = isWithinBounds(elementLeft)
    right = isWithinBounds(elementRight)
    (if above then "top" else (if below then "bottom" else (if left then "left" else (if right then "right" else "right"))))
