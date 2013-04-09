# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
#=require <shaders.coffee>
#=require <shapes.coffee>
#=require <texture.dataurl.coffee>
#=require <terrain.dataurl.coffee>

$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  ticks = 0
  tick_time = []
  startDate = null
  paused = 0

  camera = {}
  shapes = []
  pMatrix = null
  mMatrix = null

  matrixStack = []

  keyboard = []

  status = ( str ) ->
    status_box.empty()
    status_box.append str

  pushMatrix = ( m ) ->
    new_m = mat4.create()
    mat4.set m, new_m
    matrixStack[m] = [] if not matrixStack[m]
    matrixStack[m].push new_m

  popMatrix = ( m ) ->
    throw "invalid pop" if ! matrixStack[m] or matrixStack[m].length <= 0
    mat4.set matrixStack[m].pop(), m

  initialize = ->
    if ! gl
      status 'Init failed...'
      return

    gl.enable gl.DEPTH_TEST
    gl.clearColor 0.1, 0.1, 0.1, 1

    #gl.blendFunc gl.SRC_ALPHA, gl.ONE
    #gl.enable gl.BLEND;
    #gl.disable gl.DEPTH_TEST;

    initShaders gl

    startDate = new Date()

    pyramid_center = [ -1.5, 1, -7 ]
    shapes.push( new Pyramid gl, pyramid_center )

    cube_center = [ 1.5, 1, -7 ]
    shapes.push( new TextureCube gl, cube_center, texture_data_url )

    terrain_center = [ 0, 0, 0 ]
    shapes.push( new Terrain gl, terrain_center, terrain_data_url )

    document.onkeydown = (e) -> keyboard[ e.keyCode ] = 1
    document.onkeyup = (e) -> keyboard[ e.keyCode ] = 0

    camera.posX = 0
    camera.posY = 2
    camera.posZ = 0
    camera.yaw = camera.pitch = 0

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

    addLighting program
    updateInput camera, keyboard

    pushMatrix mMatrix

    mat4.rotate mMatrix, camera.pitch, [ 1, 0, 0 ]
    mat4.rotate mMatrix, camera.yaw, [ 0, 1, 0 ]
    mat4.translate mMatrix, [ -camera.posX, -camera.posY, -camera.posZ ]

    for s in shapes
      s.update elapsed

      pushMatrix mMatrix
      s.draw gl, pMatrix, mMatrix, program
      popMatrix mMatrix

    popMatrix mMatrix

    fps = Math.floor(ticks  / elapsed)
    if ticks > 100
      last_100_ticks_elapsed = (now.getTime() - tick_time[0].getTime()) / 1000;
      fps = Math.floor( 100 / last_100_ticks_elapsed )

    status 'Running... fps=' + fps

    requestAnimFrame render

  updateInput = (camera,keyboard) ->
    linearSpeed = 0.05
    angularSpeed = 0.03

    if keyboard[87] # 'w'
      camera.posX -= linearSpeed * Math.sin( camera.yaw )
      camera.posZ -= linearSpeed * Math.cos( camera.yaw )
    if keyboard[83] # 's'
      camera.posX += linearSpeed * Math.sin( camera.yaw )
      camera.posZ += linearSpeed * Math.cos( camera.yaw )
    if keyboard[65] # 'a'
      if keyboard[16] # shift
        camera.posX -= linearSpeed * Math.cos( camera.yaw )
        camera.posZ -= linearSpeed * Math.sin( camera.yaw )
      else
        camera.yaw -=angularSpeed
    if keyboard[68] # 'd'
      if keyboard[16] # shift
        camera.posX += linearSpeed * Math.cos( camera.yaw )
        camera.posZ += linearSpeed * Math.sin( camera.yaw )
      else
        camera.yaw +=angularSpeed
    if keyboard[69] # 'e'
      camera.pitch -= angularSpeed
    if keyboard[81] # 'q'
      camera.pitch += angularSpeed

  addLighting = (program) ->
    gl.useProgram program
    gl.uniform3f program.uniforms["uLightDirection"], -1, 1, 1
    gl.uniform3f program.uniforms["uAmbientColor"], 0, 0, 0
    gl.uniform3f program.uniforms["uDirectionalColor"], 1, 1, 1

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
