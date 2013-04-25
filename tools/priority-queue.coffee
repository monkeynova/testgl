# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

class PriorityQueue
  constructor: (cmp) ->
    @_cmp = cmp
    @list = []
    @reverse = []

  size: -> @list.length

  pop: ->
    item = @peek()

    if @list.length <= 1
      @list = []
      @reverse = []
    else
      @list[0] = @list.pop()
      @reverse[ @list[0].id ] = 0
      @_heapify_down 0

    return item

  push: (item) ->
    @reverse[ item.id ] = @list.length
    @list.push item

    @_heapify_up @list.length - 1

    return

  peek: ->
    return @list[0]

  invalidateItem: (item) ->
    if item.id == undefined
      throw new Error "invalidateItem cannot be called on items with no id"

    pos = @reverse[item.id]

    if pos == undefined
      throw new Error "invalidating item not in queue?"

    if @list[pos] != item
      throw new Error "reverse index is inconsistent"

    if ! @_heapify_up pos
      @_heapify_down pos

    return

  _heapify_up: (pos) ->
    ret = false

    while pos > 0
      parent = Math.floor(pos/2)
      if @_cmp( @list[parent], @list[pos] ) < 0
        break

      pos = @_swap pos, parent
      ret = true

    return ret

  _heapify_down: (pos) ->
    ret = false
    while 2 * pos + 1 < @list.length
      if @_cmp( @list[pos], @list[2*pos] ) > 0
        pos = @_swap pos, 2 * pos
        ret = true
      else if @_cmp( @list[pos], @list[2*pos + 1] ) > 0
        pos = @_swap pos, 2 * pos + 1
        ret = true
      else
        break

    return ret

  _swap: (p1,p2) ->
    [ @list[p1], @list[p2] ] = [ @list[p2], @list[p1] ]
    @reverse[ @list[p1].id ] = p1
    @reverse[ @list[p2].id ] = p2
    return p2


exports.PriorityQueue = PriorityQueue
