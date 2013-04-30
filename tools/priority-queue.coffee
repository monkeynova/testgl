# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

class PriorityQueue
  constructor: (cmp) ->
    @_cmp = cmp
    @list = [ 'null' ]
    @reverse = []
    @paranoid = false

  doAssert: -> @paranoid = true

  size: -> @list.length - 1

  pop: ->
    item = @peek()
    delete @reverse[ item.id ] if item

    if @list.length <= 2
      @list = [ 'null' ]
      @reverse = []
    else
      @list[1] = @list.pop()
      @reverse[ @list[1].id ] = 1
      @_heapify_down 1

    @assert() if @paranoid

    return item

  push: (item) ->
    @reverse[ item.id ] = @list.length
    @list.push item

    @_heapify_up @list.length - 1

    @assert() if @paranoid

    return

  peek: ->
    return @list[1]

  assert: ->
    i = 1
    while 2 * i + 1 < @list.length
      if @_cmp( @list[i], @list[ 2 * i ] ) > 0
        throw new Error "cmp( #{i}, #{2 * i} ) > 0"
      if @_cmp( @list[i], @list[ 2 * i + 1 ] ) > 0
        throw new Error "cmp( #{i}, #{2 * i} ) > 0"
      i++

    if 2 * i < @list.length
      if @_cmp( @list[i], @list[ 2 * i ] ) > 0
        throw new Error "cmp( #{i}, #{2 * i} ) > 0"

  _item2pos: (item) ->
    if item.id == undefined
      throw new Error "invalidateItem cannot be called on items with no id"

    pos = @reverse[item.id]

    if pos == undefined
      throw new Error "item not in queue?"

    if @list[pos] != item
      throw new Error "reverse index is inconsistent " + JSON.stringify( @list[pos] ) + " != " + JSON.stringify( item )

    return pos

  removeItem: (item) ->
    pos = @_item2pos item

    if pos != @list.length - 1
      @_swap pos, @list.length - 1

    @list.pop()
    delete @reverse[ item.id ]

    if pos < @list.length - 1
      if ! @_heapify_up pos
        @_heapify_down pos

    @assert() if @paranoid

    return

  invalidateItem: (item) ->
    pos = @_item2pos item

    if ! @_heapify_up pos
      @_heapify_down pos

    @assert() if @paranoid

    return

  _heapify_up: (pos) ->
    ret = false

    while pos > 1
      parent = Math.floor(pos/2)
      if @_cmp( @list[parent], @list[pos] ) < 0
        break

      pos = @_swap pos, parent
      ret = true

    return ret

  _heapify_down: (pos) ->
    ret = false
    while 2 * pos + 1 < @list.length
      if @_cmp( @list[pos], @list[2*pos + 1] ) > 0 # 2n+1 is better
        if @_cmp( @list[2 * pos], @list[2*pos + 1] ) < 0 # 2n is best
          pos = @_swap pos, 2 * pos
          ret = true
        else # 2n + 1 is best
          pos = @_swap pos, 2 * pos + 1
          ret = true  
      else if @_cmp( @list[pos], @list[2*pos] ) > 0  # 2n is better, 2n+1 is not
        pos = @_swap pos, 2 * pos
        ret = true
      else
        break

    if 2 * pos < @list.length
      if @_cmp( @list[pos], @list[2*pos] ) > 0  # 2n is better, 2n+1 doesn't exist
        pos = @_swap pos, 2 * pos
        ret = true

    return ret

  _swap: (p1,p2) ->
    [ @list[p1], @list[p2] ] = [ @list[p2], @list[p1] ]
    @reverse[ @list[p1].id ] = p1
    @reverse[ @list[p2].id ] = p2
    return p2


exports.PriorityQueue = PriorityQueue
