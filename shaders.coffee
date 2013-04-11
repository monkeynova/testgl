# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
default_shader = null
wire_shader = null

initShaders = (gl) ->
  default_shader = initNamedShader gl, 'shader'
  wire_shader = initNamedShader gl, 'wire'

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
      "aVertexColor",
      "aTextureCoord",
    ]

  shader.attributes = []

  for name in attribute_names
    location = gl.getAttribLocation shader, name
    if location >= 0
      shader.attributes[name] = location
      gl.enableVertexAttribArray shader.attributes[name]
      console.log shader_name + ": " + name + "=" + shader.attributes[name]        

  uniform_names =
    [
      "uPMatrix",
      "uMVMatrix",
      "uNMatrix",
      "uSampler",
      "uUseTexture",
      "uLightPosition",
      "uAmbientColor",
      "uDirectionalColor",
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
    alert gl.getShaderInfoLog( shader )
    return

  return shader      
