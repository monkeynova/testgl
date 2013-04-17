# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
#=require <shaders.coffee>
#=require <shapes.coffee>
#=require <texture.dataurl.coffee>
#=require <terrain.dataurl.coffee>
#=require <wave_bumpmap.dataurl.coffee>
#=require <pyramid.model.dataurl.coffee>
#=require <cube.model.dataurl.coffee>
#=require <sphere.model.dataurl.coffee>
#=require <torus.model.dataurl.coffee>
#=require <trefoil.model.dataurl.coffee>
#=require <humanoid.skel.dataurl.coffee>

$ ->
  canvas = document.getElementById 'viewport'
  status_box = $ '#status'
  gl = canvas.getContext 'experimental-webgl' if canvas.getContext
  startDate = null
  lastRenderDate = null
  avg_fps = null

  paused = 0

  camera = { pos : [ 0, 2, 0 ], orientation : [ 0, 0, 0, 1 ] }
  shapes = []
  pMatrix = null
  mvMatrix = null
  lightSphere = null
  lightPosition = null

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

#    grid = new Axes gl, [ 0, 0, 0 ]
#    shapes.push grid

#    pyramid_center = [ -1.5, 1, -7 ]
#    pyramid = new JSONModel gl, pyramid_center, pyramid_model_data_url
#    pyramid.animate 1/3, [ 0, 1, 0 ]
#    shapes.push pyramid

    sphere_center = [ 0, 0, 0 ]
    lightSphere = new JSONModel gl, sphere_center, sphere_model_data_url
    shapes.push lightSphere

    trefoil_center = [ -1.5, 1, -7 ]
    trefoil = new JSONModel gl, trefoil_center, trefoil_model_data_url
    trefoil.animate 1/3, [ -1, 1, 1 ]
    shapes.push trefoil

#    cube_center = [ 1.5, 1, -7 ]
#    cube = new JSONModel gl, cube_center, cube_model_data_url
#    cube.animate 1/10, [ 1, 1, 1 ]
#    shapes.push cube

    cube_center = [ 1.5, 1, -7 ]
    cube = new NormalCube gl, cube_center, wave_bumpmap_data_url
    cube.animate 1/10, [ 1, 1, 1 ]
    shapes.push cube

#    torus_center = [ 1.5, 1, -7 ]
#    torus = new JSONModel gl, torus_center, torus_model_data_url
#    torus.animate 1/3, [ 1, 0, 0 ]
#    shapes.push torus

    terrain_center = [ -64, -5, -128 ]
    shapes.push( new Terrain gl, terrain_center, terrain_data_url )

    document.onkeydown = (e) -> keyboard[ e.keyCode ] = 1
    document.onkeyup = (e) -> keyboard[ e.keyCode ] = 0

    camera.pos = vec3.create camera.pos
    camera.orientation = quat4.create camera.orientation

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

    mat4.multiply mvMatrix, quat4.toMat4 camera.orientation
    mat4.translate mvMatrix, vec3.scale( camera.pos, -1, vec3.create() )

    addLighting vertex_lighting_shader, mvMatrix, (now.getTime() - startDate.getTime()) / 1000
    addLighting pixel_lighting_shader, mvMatrix, (now.getTime() - startDate.getTime()) / 1000

    for s in shapes
      s.update elapsed

      pushMatrix mvMatrix
      s.drawSolid gl, pMatrix, mvMatrix, vertex_lighting_shader, pixel_lighting_shader
      s.drawWire  gl, pMatrix, mvMatrix, wire_shader
      popMatrix mvMatrix

    popMatrix mvMatrix

    fps = if elapsed then 1  / elapsed else 0

    avg_fps = if avg_fps == null then fps else 0.99 * avg_fps + 0.01 * fps

    status 'Running... fps=' + Math.floor( avg_fps )

    requestAnimFrame render

  updateInput = (camera,keyboard) ->
    linearSpeed = 0.20
    angularSpeed = 0.03

    if keyboard[87] # 'w'
      vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ 0, 0, -linearSpeed ]
    if keyboard[83] # 's'
      vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ 0, 0, linearSpeed ]
    if keyboard[65] # 'a'
      if keyboard[16] # shift
        vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ -linearSpeed, 0, 0 ]
      else
        quat4.multiply camera.orientation, quat4.create [ 0, Math.sin( angularSpeed / 2 ), 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[68] # 'd'
      if keyboard[16] # shift
        vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ linearSpeed, 0, 0 ]
      else
        quat4.multiply camera.orientation, quat4.create [ 0, -Math.sin( angularSpeed / 2 ), 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[69] # 'e'
      if keyboard[16] # shift
        vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ 0, linearSpeed, 0 ]
      else
        quat4.multiply camera.orientation, quat4.create [ Math.sin( angularSpeed / 2 ), 0, 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[81] # 'q'
      if keyboard[16] # shift
        vec3.add camera.pos, quat4.multiplyVec3 camera.orientation, vec3.create [ 0, -linearSpeed, 0 ]
      else
        quat4.multiply camera.orientation, quat4.create [ -Math.sin( angularSpeed / 2 ), 0, 0, Math.cos( angularSpeed / 2 ) ]

   addLighting = (program,mvMatrix,fullElapsed) ->
    gl.useProgram program

    lightAngle = fullElapsed * 2 * Math.PI / 10
    lightPosition = vec3.create [ 50 * Math.cos( lightAngle ), 50, 50 * Math.sin( lightAngle ) ]
    lightSphere.center = lightPosition
    mat4.multiplyVec3 mvMatrix, lightPosition

    gl.uniform3fv program.uniforms["uLightPosition"], lightPosition
    gl.uniform3f program.uniforms["uAmbientColor"], 0.2, 0.2, 0.2
    gl.uniform3f program.uniforms["uDirectionalColor"], 0.6, 0.6, 0.6
    gl.uniform3f program.uniforms["uSpecularColor"], 1, 1, 1

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
