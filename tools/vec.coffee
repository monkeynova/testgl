# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-

exports.add = (v1,v2) ->
  return [ v1[0] + v2[0], v1[1] + v2[1], v1[2] + v2[2] ]

exports.dot = (v1, v2) ->
  return v1[0] * v2[0] + v1[1] * v2[1] + v1[2] * v2[2]

exports.scale = (v,s) ->
  return [ v[0] * s, v[1] * s, v[2] * s ]

exports.normalize = (v) ->
  return exports.scale v, 1 / Math.sqrt( exports.dot v, v )

exports.cross = (v1,v2) ->
  return [ v1[1] * v2[2] - v2[1] * v1[2], -(v1[0] * v2[2] - v1[2] * v2[0]), v1[0] * v2[1] - v1[1] * v2[0] ]

