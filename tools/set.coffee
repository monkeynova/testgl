# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

class Set
  constructor: (maybe_hash,rest...) ->
    if rest.length == 0 && typeof maybe_hash == "object"
      @_items = maybe_hash
    else
      @_items = {}
      i = maybe_hash
      @_items[if typeof i == "object" then i.id else i] = i
      for i in rest
        @_items[if typeof i == "object" then i.id else i] = i

  list: -> val for key, val of @_items

  size: -> Object.keys( @_items ).length

  contains: (item) ->
    return @_items[if typeof item == "object" then item.id else item]?

  union: (other) ->
    items = {}
    for id,item of @_items
      items[id] = item if ! items[id]
    for id,item of other._items
      items[id] = item if ! items[id]
    return new Set( items )

  intersection: (other) ->
    items = {}
    for id,item of @_items
      items[id] = item if other._items[id]?
    return new Set( items )

  minus: (other) ->
    items = {}
    for id,item of @_items
      items[id] = item if ! other._items[id]?
    return new Set( items )

exports.Set = Set

