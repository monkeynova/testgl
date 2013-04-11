# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
#=require <shaders.coffee>
#=require <shapes.coffee>
#=require <texture.dataurl.coffee>
#=require <terrain.dataurl.coffee>
#=require <pyramid.model.dataurl.coffee>
#=require <cube.model.dataurl.coffee>
#=require <humanoid.skel.dataurl.coffee>

$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  startDate = null
  lastRenderDate = null
  avg_fps = null

  paused = 0

  camera = {}
  shapes = []
  pMatrix = null
  mvMatrix = null

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
    gl.clearColor 0.5, 0.8, 1, 1

    #gl.blendFunc gl.SRC_ALPHA, gl.ONE
    #gl.enable gl.BLEND;
    #gl.disable gl.DEPTH_TEST;

    initShaders gl

    startDate = new Date()

    grid = new Axes gl, [ 0, 0, 0 ]
    shapes.push grid

    pyramid_center = [ -1.5, 1, -7 ]
    #shapes.push( new Pyramid gl, pyramid_center )
    pyramid = new JSONModel gl, pyramid_center, pyramid_model_data_url
    pyramid.animate 1/3, [ 0, 1, 0 ]
    shapes.push pyramid

    cube_center = [ 1.5, 1, -7 ]
    #shapes.push( new TextureCube gl, cube_center, texture_data_url )
    cube = new JSONModel gl, cube_center, cube_model_data_url
    cube.animate 1/10, [ 1, 1, 1 ]
    shapes.push cube

    terrain_center = [ -64, -5, -128 ]
#    shapes.push( new Terrain gl, terrain_center, terrain_data_url )

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
    elapsed = if lastRenderDate then (now.getTime() - lastRenderDate.getTime()) / 1000 else 0
    lastRenderDate = now

    updateInput camera, keyboard

    pushMatrix mvMatrix

    mat4.rotate mvMatrix, camera.pitch, [ 1, 0, 0 ]
    mat4.rotate mvMatrix, camera.yaw, [ 0, 1, 0 ]
    mat4.translate mvMatrix, [ -camera.posX, -camera.posY, -camera.posZ ]

    addLighting default_shader, mvMatrix, (now.getTime() - startDate.getTime()) / 1000

    for s in shapes
      s.update elapsed

      pushMatrix mvMatrix
      s.drawSolid gl, pMatrix, mvMatrix, default_shader
      s.drawWire  gl, pMatrix, mvMatrix, wire_shader
      popMatrix mvMatrix

    popMatrix mvMatrix

    fps = if elapsed then 1  / elapsed else 0

    avg_fps = if avg_fps == null then fps else 0.99 * avg_fps + 0.01 * fps

    status 'Running... fps=' + Math.floor( avg_fps )

    requestAnimFrame render

  updateInput = (camera,keyboard) ->
    linearSpeed = 0.05
    angularSpeed = 0.03

    if keyboard[87] # 'w'
      camera.posX += linearSpeed * Math.sin( camera.yaw )
      camera.posZ -= linearSpeed * Math.cos( camera.yaw )
    if keyboard[83] # 's'
      camera.posX -= linearSpeed * Math.sin( camera.yaw )
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

   addLighting = (program,mvMatrix,fullElapsed) ->
    gl.useProgram program

    lightAngle = fullElapsed * 2 * Math.PI / 10
    light_position = vec3.create [ 100 * Math.cos( lightAngle ), 100, 100 * Math.sin( lightAngle ) ]
    start_pos_string = "[" + Math.floor( light_position[0] ) + "," + Math.floor( light_position[1] ) + "," + Math.floor( light_position[2] ) + "]"
    mat4.multiplyVec3 mvMatrix, light_position
    mv_pos_string = "[" + Math.floor( light_position[0] ) + "," + Math.floor( light_position[1] ) + "," + Math.floor( light_position[2] ) + "]"
    status start_pos_string + " => " + mv_pos_string

    gl.uniform3fv program.uniforms["uLightPosition"], light_position
    gl.uniform3f program.uniforms["uAmbientColor"], 0.2, 0.2, 0.2
    gl.uniform3f program.uniforms["uDirectionalColor"], 0.8, 0.8, 0.8

  reshape = ->
    return if canvas.clientWidth == canvas.width && canvas.clientHeight == canvas.height
    canvas.width = canvas.clientWidth
    canvas.height = canvas.clientHeight
    gl.viewport 0, 0, canvas.width, canvas.height

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.width / canvas.height, 0.1, 100, pMatrix

    mvMatrix = mat4.create()
    mat4.identity mvMatrix

  initialize()
