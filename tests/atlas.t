#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

test = require( 'tap' ).test
tm = require( '../tools/test-more.coffee' )

Atlas = require( '../tools/atlas.coffee' )

test "combine_perimeter", (t) ->
  combine_perimiters = Atlas._fortest.combine_perimiters
  check = (a,b,should,m) ->
    tm.is_deeply t, canon_perimiter( combine_perimiters( a, b ) ), should, m
    tm.is_deeply t, canon_perimiter( combine_perimiters( b, a ) ), should, "#{m} (reverse)"

  t.test "simple", (t) ->
    check [ 0, 1, 2, 3 ], [ 0, 3, 4 ], [ 0, 1, 2, 3, 4 ], "wrap around"
    check [ 0, 1, 2 ], [ 1, 2, 3 ], [ 0, 1, 3, 2 ], "simple join"
    check [ 0, 1, 2 ], [ 2, 1, 3 ], [ 0, 1, 3, 2 ], "simple join; rotate"
    check [ 0, 1, 2, 3 ], [ 1, 2, 4, 5 ], [ 0, 1, 5, 4, 2, 3 ], "slightly more complex join"
    check [ 0, 1, 2 ], [ 0, 1, 2 ], [ 0, 1, 2 ], "full overlap"
    check [ 0, 1, 2 ], [ 1, 2, 0 ], [ 0, 1, 2 ], "full overlap; rotate"
    check [ 0, 1, 2, 3 ], [ 0, 3, 4 ], [ 0, 1, 2, 3, 4 ], "wrap around"
    check [ 0, 1, 2 ], [ 0, 1, 2, 3 ], [ 0, 1, 2, 3 ], "subset perimiter"
    t.end()

  t.test "errors", (t) ->
    doesError = (a,b,e,m) -> tm.throws_like t, ( -> combine_perimiters( a, b ) ), e, m

    doesError [ 0, 1, 2 ], [ 3, 4, 5 ], /overlap/, "attempt non-overlapping combine"
    doesError [ 0, 1, 2 ], [ 2, 3, 4 ], /single point/, "attempt tangent"
    doesError [ 0, 1, 2, 3, 4, 5, 6 ], [ 0, 1, 7, 8, 4, 5, 9 ], /disjoint/, "attempt non-disc combine"
    t.end()

  t.end()

canon_perimiter = (a) ->
  min = null
  min_pos = -1
  for i,v of a
    if min_pos == -1 || v < min
      min_pos = parseInt( i )
      min = v

  if min_pos <= 0
    return a

  ret = []
  ret = ret.concat ( a[i] for i in [ min_pos .. (a.length - 1) ] )
  ret = ret.concat ( a[i] for i in [ 0 .. (min_pos - 1) ] )

  if ret[1] > ret[ ret.length - 1 ]
    save = ret.shift()
    ret = ret.reverse()
    ret.unshift save

  return ret
