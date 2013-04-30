#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

test = require( 'tap' ).test

pq = require( '../tools/priority-queue.coffee' ).PriorityQueue

is_deeply = (t,got,expect,message) -> t.is( JSON.stringify(got), JSON.stringify(expect), message )

test "in-order add", (t) ->
  queue = new pq (a,b) -> a-b
  queue.doAssert()
  for i in [ 1 .. 5 ]
    queue.push i
  t.is( queue.size(), 5, "queue size" )
  for i in [ 1 .. 5 ]
    t.is( queue.pop(), i, "in order #{i}" )
  t.is( queue.size(), 0, "end of queue (size)" )
  t.end()

test "reverse-order add", (t) ->
  queue = new pq (a,b) -> a-b
  queue.doAssert()
  for i in [ 1 .. 5 ].reverse()
    queue.push i
  for i in [ 1 .. 5 ]
    t.is( queue.pop(), i, "reverse order #{i}" )
  t.notOk( queue.pop(), "end of queue (null)" )
  t.end()

test "reverse-priority add", (t) ->
  queue = new pq (a,b) -> b-a
  queue.doAssert()
  for i in [ 1 .. 5 ]
    queue.push i
  for i in [ 1 .. 5 ].reverse()
    t.is( queue.pop(), i, "reverse-priority order #{i}" )
  t.end()

test "error field add", (t) ->
  queue = new pq (a,b) -> a.error - b.error
  queue.doAssert()

  names = [ "0", "a", "b", "c", "d", "e" ]

  for i in [ 1 .. 5 ].reverse()
    queue.push { error : i, name : names[i] }
  for i in [ 1 .. 5 ]
    is_deeply( t, queue.pop(), { error : i, name : names[i] }, "reverse-priority order #{i}" )
  t.end()

test "invalidate item", (t) ->
  queue = new pq (a,b) -> a.error - b.error
  queue.doAssert()

  items = [
      { error : 1, name : "a", id : 1 },
      { error : 2, name : "b", id : 2 },
      { error : 3, name : "c", id : 3 },
      { error : 4, name : "d", id : 4 },
      { error : 5, name : "e", id : 5 },
    ]

  for tem,i in items
    i.toString = -> i

  for i in items
    queue.push i

  items[2].error = 0

  queue.invalidateItem items[2]

  should = [
      { error : 0, name : "c", id : 3 },
      { error : 1, name : "a", id : 1 },
      { error : 2, name : "b", id : 2 },
      { error : 4, name : "d", id : 4 },
      { error : 5, name : "e", id : 5 },
    ]

  for expect, i in should
    is_deeply( t, queue.pop(), expect, "invalidate item #{i}" )
  t.end()

test "remove item", (t) ->
  queue = new pq (a,b) -> a.error - b.error
  queue.doAssert()

  items = [
      { error : 1, name : "a", id : 1 },
      { error : 2, name : "b", id : 2 },
      { error : 3, name : "c", id : 3 },
      { error : 4, name : "d", id : 4 },
      { error : 5, name : "e", id : 5 },
    ]

  for tem,i in items
    i.toString = -> i

  for i in items
    queue.push i

  queue.removeItem items[2]

  should = [
      { error : 1, name : "a", id : 1 },
      { error : 2, name : "b", id : 2 },
      { error : 4, name : "d", id : 4 },
      { error : 5, name : "e", id : 5 },
    ]

  for expect, i in should
    is_deeply( t, queue.pop(), expect, "invalidate item #{i}" )
  t.end()
