#!/usr/bin/env coffee
# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

test = require( 'tap' ).test
tm = require( '../tools/test-more.coffee' )

Set = require( '../tools/set.coffee' ).Set

test "simple", (t) ->
  s = new Set 1, 2, 3
  t.ok s.contains( 1 ), "1 is in"
  t.notok s.contains( 4 ), "4 is out"
  tm.is_deeply( t, s.list().sort( (a,b) -> a - b ), [ 1, 2, 3 ],  "list is correct" )
  t.is s.size(), 3, "size is 3"
  t.end()

test "union", (t) ->
  s1 = new Set 1, 2, 3
  s2 = new Set 1, 2, 4
  s = s1.union s2
  t.ok s.contains( 1 ), "1 is in"
  t.ok s.contains( 4 ), "4 is in"
  t.notok s.contains( 5 ), "5 is out"
  t.is s.size(), 4, "size is 4"
  t.end()

test "intersection", (t) ->
  s1 = new Set 1, 2, 3
  s2 = new Set 1, 2, 4
  s = s1.intersection s2
  t.ok s.contains( 1 ), "1 is in"
  t.notok s.contains( 4 ), "4 is out"
  t.notok s.contains( 5 ), "5 is out"
  t.is s.size(), 2, "size is 2"
  t.end()

test "minus", (t) ->
  s1 = new Set 1, 2, 3
  s2 = new Set 1, 2, 4
  s = s1.minus s2
  t.ok s.contains( 3 ), "3 is in"
  t.notok s.contains( 4 ), "4 is out"
  t.notok s.contains( 5 ), "5 is out"
  t.is s.size(), 1, "size is 1"
  t.end()
