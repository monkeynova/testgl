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
  lighting = {
      ambient : [ 0.2, 0.2, 0.2 ],
      directional : [ 0.6, 0.6, 0.6 ],
      specular : [ 1, 1, 1 ],
    }
  screen = null
  shapes = []
  pMatrix = null
  mvMatrix = null
  lightSphere = null

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

    now = new Date()
    elapsed = if lastRenderDate then (now.getTime() - lastRenderDate.getTime()) / 1000 else 0
    lastRenderDate = now

    for s in shapes
      s.update elapsed

    updateInput camera, keyboard

    mat4.identity mvMatrix
    mat4.multiply mvMatrix, quat4.toMat4 camera.orientation
    mat4.translate mvMatrix, vec3.scale( camera.pos, -1, vec3.create() )

    addLighting shaders, mvMatrix, (now.getTime() - startDate.getTime()) / 1000

    gl.viewport 0, 0, canvas.width, canvas.height
    gl.clearColor 0.5, 0.8, 1, 1
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    for s in shapes
      s.draw gl, pMatrix, mvMatrix, shaders

    renderShadowTexture shaders

    fps = if elapsed then 1  / elapsed else 0

    avg_fps = if avg_fps == null then fps else 0.99 * avg_fps + 0.01 * fps

    status 'Running... fps=' + Math.floor( avg_fps )

    requestAnimFrame render

  updateInput = (camera,keyboard) ->
    linearSpeed = 0.20
    angularSpeed = 0.03

    linearMove = null
    angularMove = null

    if keyboard[87] # 'w'
      linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ 0, 0, -linearSpeed ]
    if keyboard[83] # 's'
      linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ 0, 0, linearSpeed ]
    if keyboard[65] # 'a'
      if keyboard[16] # shift
        linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ -linearSpeed, 0, 0 ]
      else
        angularMove = quat4.create [ 0, Math.sin( angularSpeed / 2 ), 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[68] # 'd'
      if keyboard[16] # shift
        linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ linearSpeed, 0, 0 ]
      else
        angularMove = quat4.create [ 0, -Math.sin( angularSpeed / 2 ), 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[69] # 'e'
      if keyboard[16] # shift
        linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ 0, linearSpeed, 0 ]
      else
        angularMove = quat4.create [ Math.sin( angularSpeed / 2 ), 0, 0, Math.cos( angularSpeed / 2 ) ]
    if keyboard[81] # 'q'
      if keyboard[16] # shift
        linearMove = quat4.multiplyVec3 camera.orientation, vec3.create [ 0, -linearSpeed, 0 ]
      else
        angularMove = quat4.create [ -Math.sin( angularSpeed / 2 ), 0, 0, Math.cos( angularSpeed / 2 ) ]

    vec3.add camera.pos, linearMove if linearMove
    quat4.multiply camera.orientation, angularMove if angularMove

   addLighting = (shaders,mvMatrix,fullElapsed) ->

    lightAngle = fullElapsed * 2 * Math.PI / 10
    lighting.position = vec3.create [ 50 * Math.cos( lightAngle ), 50, 50 * Math.sin( lightAngle ) ]
    lightSphere.center = lighting.position

    initLighting() if ! lighting.initialized

    buildShadowTexture( shaders )

    for shader in [ shaders["vertex-lighting"], shaders["pixel-lighting"] ]
      gl.useProgram shader

      gl.uniform3fv shader.uniforms["uLightPosition"], lighting.position
      gl.uniform3fv shader.uniforms["uAmbientColor"], lighting.ambient
      gl.uniform3fv shader.uniforms["uDirectionalColor"], lighting.directional
      gl.uniform3fv shader.uniforms["uSpecularColor"], lighting.specular

      gl.uniform1f shader.uniforms["uUseShadowTexture"], false
      gl.activeTexture gl.TEXTURE0
      gl.bindTexture gl.TEXTURE_2D, lighting.texture
      gl.uniform1f shader.uniforms["uShadowTexture"], 0

      gl.uniformMatrix4fv shader.uniforms["uLightPMatrix"], false, lighting.pMatrix
      gl.uniformMatrix4fv shader.uniforms["uLightMVMatrix"], false, lighting.mvMatrix

  renderShadowTexture = (shaders) ->
    drawScreen( shaders, lighting.texture, 1 - 0.2 / canvas.aspect, 0.8, 0.2 / canvas.aspect, 0.2 )

  buildShadowTexture = (shaders) ->
    shader = shaders["shadow"]

    if ! shader
      console.error "no shadow shader"
      return;

    gl.bindFramebuffer gl.FRAMEBUFFER, lighting.framebuffer

    gl.useProgram shader

    gl.viewport( 0, 0, lighting.framebuffer.width, lighting.framebuffer.height )
    gl.clearColor 0, 0, 0, 1
    gl.clear gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT

    lighting.mvMatrix = mat4.lookAt lighting.position, [ 0, 0, 0 ], [ 0, 1, 0 ]

    for s in shapes
      if s != lightSphere
        s.drawSolid gl, lighting.pMatrix, lighting.mvMatrix, shader # TODO: rethink peeking

    gl.bindTexture gl.TEXTURE_2D, lighting.texture
    gl.generateMipmap gl.TEXTURE_2D
    gl.bindTexture gl.TEXTURE_2D, null

    gl.bindFramebuffer gl.FRAMEBUFFER, null

  initLighting = ->
    lighting.framebuffer = gl.createFramebuffer()
    gl.bindFramebuffer gl.FRAMEBUFFER, lighting.framebuffer
    lighting.framebuffer.width = 256
    lighting.framebuffer.height = 256

    lighting.texture = gl.createTexture()
    gl.bindTexture gl.TEXTURE_2D, lighting.texture
    gl.texImage2D gl.TEXTURE_2D, 0, gl.RGBA,
      lighting.framebuffer.width, lighting.framebuffer.height,
      0, gl.RGBA, gl.UNSIGNED_BYTE, null
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR
    gl.texParameteri gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_NEAREST
    gl.generateMipmap gl.TEXTURE_2D
    gl.bindTexture gl.TEXTURE_2D, null

    lighting.renderbuffer = gl.createRenderbuffer()
    gl.bindRenderbuffer gl.RENDERBUFFER, lighting.renderbuffer
    gl.renderbufferStorage gl.RENDERBUFFER, gl.DEPTH_COMPONENT16, lighting.framebuffer.width, lighting.framebuffer.height

    gl.framebufferTexture2D gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, lighting.texture, 0
    gl.framebufferRenderbuffer gl.FRAMEBUFFER, gl.DEPTH_ATTACHMENT, gl.RENDERBUFFER, lighting.renderbuffer

    gl.bindRenderbuffer gl.RENDERBUFFER, null
    gl.bindFramebuffer gl.FRAMEBUFFER, null

    lighting.pMatrix = mat4.perspective 90, 1, 0.1, 100

    lighting.initialized = true


  drawScreen = (shaders, texture, x, y, width, height ) ->
    if ! screen
      initScreen()

    shader = shaders["screen"]

    if ! shader
      console.error "no screen shader"
      return

    gl.useProgram shader

    gl.activeTexture gl.TEXTURE0
    gl.bindTexture gl.TEXTURE_2D, texture
    gl.uniform1i shader.uniforms["uTextureSampler"], 0

    gl.uniform2f shader.uniforms["u2DOffset"], x, y
    gl.uniform2f shader.uniforms["u2DStride"], width, height

    gl.bindBuffer gl.ARRAY_BUFFER, screen.vertices
    gl.vertexAttribPointer shader.attributes["aVertexPosition"], screen.vertices.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ARRAY_BUFFER, screen.texture
    gl.vertexAttribPointer shader.attributes["aTextureCoord"], screen.texture.itemSize, gl.FLOAT, false, 0, 0

    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, screen.index
    gl.drawElements gl.TRIANGLES, screen.index.numItems, gl.UNSIGNED_SHORT, 0

  initScreen = ->
    screen = {}

    vertices = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, vertices
    vertices.js = [ 0, 0, 0, 1, 1, 0, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( vertices.js ), gl.STATIC_DRAW
    vertices.itemSize = 2
    vertices.numItems = vertices.js.length / vertices.itemSize

    screen.vertices = vertices

    texture = gl.createBuffer()
    gl.bindBuffer gl.ARRAY_BUFFER, texture
    texture.js = [ 0, 0, 0, 1, 1, 0, 1, 1 ]
    gl.bufferData gl.ARRAY_BUFFER, new Float32Array( texture.js ), gl.STATIC_DRAW
    texture.itemSize = 2
    texture.numItems = texture.js.length / texture.itemSize

    screen.texture = texture

    index = gl.createBuffer()
    gl.bindBuffer gl.ELEMENT_ARRAY_BUFFER, index
    index.js = [ 0, 1, 2, 1, 2, 3 ]
    gl.bufferData gl.ELEMENT_ARRAY_BUFFER, new Uint16Array( index.js ), gl.STATIC_DRAW
    index.itemSize = 1
    index.numItems = index.js.length / index.itemSize

    screen.index = index

  reshape = ->
    return if canvas.clientWidth == canvas.width && canvas.clientHeight == canvas.height
    canvas.width = canvas.clientWidth
    canvas.height = canvas.clientHeight
    canvas.aspect = canvas.width / canvas.height

    pMatrix = mat4.create()
    mat4.perspective 45, canvas.aspect, 0.1, 100, pMatrix

    mvMatrix = mat4.create()
    mat4.identity mvMatrix

  initialize()
