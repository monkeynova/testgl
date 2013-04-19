# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
shaders = []

initShaders = (gl) ->
  shaders["pixel-lighting"] = initNamedShader gl, 'pixel-lighting'
  shaders["screen"] = initNamedShader gl, 'screen'
  shaders["shadow"] = initNamedShader gl, 'shadow'
  shaders["vertex-lighting"] = initNamedShader gl, 'vertex-lighting'
  shaders["wire"] = initNamedShader gl, 'wire'

initNamedShader = (gl,shader_name) ->
  shader = null

  fragmentShader = getShader gl, shader_name + '-fs'
  vertexShader = getShader gl, shader_name + '-vs'

  shader = gl.createProgram()
  gl.attachShader shader, vertexShader
  gl.attachShader shader, fragmentShader
  gl.linkProgram shader

  if ( ! gl.getProgramParameter shader, gl.LINK_STATUS )
    status 'Shader link failed'
    return;

  gl.useProgram shader

  attribute_names =
    [
      "aVertexPosition",
      "aVertexNormal",
      "aVertexTangent",
      "aVertexColor",
      "aTextureCoord",
      "aNormalCoord",
    ]

  shader.attributes = []

  for name in attribute_names
    location = gl.getAttribLocation shader, name
    console.log shader_name + ": " + name + "=" + location
    if location >= 0
      shader.attributes[name] = location
      gl.enableVertexAttribArray shader.attributes[name]

  uniform_names =
    [
      "uProjectionMatrix",
      "uViewMatrix",
      "uModelMatrix",
      "uNMatrix",
      "uTextureSampler",
      "uUseTexture",
      "uNormalSampler",
      "uUseNormalMap",
      "uShadowSampler",
      "uUseShadowTexture",
      "uLightPMatrix",
      "uLightMVMatrix",
      "uLightPosition",
      "uAmbientColor",
      "uDirectionalColor",
      "uSpecularColor",
      "uMaterialShininess",
      "u2DOffset",
      "u2DStride",
    ]

  shader.uniforms = []

  for name in uniform_names
    shader.uniforms[name] = gl.getUniformLocation shader, name
    console.log shader_name + ": " + name + "=" + shader.uniforms[name]        

  return shader

getShader = (gl, id) ->
  shaderScript = document.getElementById id
  return if ! shaderScript

  if ( shaderScript.type == "x-shader/x-fragment" )
    shader = gl.createShader( gl.FRAGMENT_SHADER )
  else if ( shaderScript.type == "x-shader/x-vertex" )
    shader = gl.createShader( gl.VERTEX_SHADER )
  else
    alert( "unknown type: " + shaderScript.type + " for id " + id )
    return

  gl.shaderSource shader, shaderScript.innerHTML
  gl.compileShader shader

  if ( ! gl.getShaderParameter( shader, gl.COMPILE_STATUS ) )
    alert "error compiling " + id + "\n" + gl.getShaderInfoLog( shader )
    return

  return shader      
