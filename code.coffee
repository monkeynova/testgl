# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
#=require <shaders.coffee>
#=require <shapes.coffee>

$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  ticks = 0
  tick_time = []
  startDate = null
  paused = 0

  shapes = []
  pMatrix = null
  mMatrix = null

  status = ( str ) ->
    status_box.empty()
    status_box.append str

  pushMatrix = ( m ) ->
    new_m = mat4.create()
    mat4.set m, new_m
    m.stack = [] if ! m.stack
    new_m.stack = m.stack
    m.stack.push new_m

  popMatrix = ( m ) ->
    throw "invalid pop" if m.stack.length <= 0
    mat4.set m.stack.pop(), m

  initialize = ->
    if ! gl
      status 'Init failed...'
      return

    gl.enable gl.DEPTH_TEST
    gl.clearColor 0.1, 0.1, 0.1, 1

    initShaders gl

    startDate = new Date()

    shapes.push( new Pyramid gl )
    shapes.push( new Cube gl )

    status 'Initialized...'
    render()

  pause = -> paused = 1
  unpause = -> paused = 0; render

  render = ->
    return if paused

    reshape()
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    now = new Date()

    elapsed = (now.getTime() - startDate.getTime()) / 1000;

    ticks++
    tick_time.push( now );
    tick_time.shift() while tick_time.length > 100

    gl.useProgram color_program

    for s in shapes
      s.update elapsed

      pushMatrix mMatrix
      s.draw gl, pMatrix, mMatrix, color_program
      popMatrix mMatrix

    fps = Math.floor(ticks  / elapsed)
    if ticks > 100
      last_100_ticks_elapsed = (now.getTime() - tick_time[0].getTime()) / 1000;
      fps = Math.floor( 100 / last_100_ticks_elapsed )

    status 'Running... fps=' + fps

    requestAnimFrame render

  reshape = ->
    return if canvas.clientWidth == canvas.width && canvas.clientHeight == canvas.height
    canvas.width = canvas.clientWidth
    canvas.height = canvas.clientHeight
    gl.viewport 0, 0, canvas.width, canvas.height

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.width / canvas.height, 0.1, 100, pMatrix

    mMatrix = mat4.create()
    mat4.identity mMatrix

  initialize()
