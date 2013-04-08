# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
program = null

initShaders = (gl) ->
  fragmentShader = getShader gl, 'shader-fs'
  vertexShader = getShader gl, 'shader-vs'

  program = gl.createProgram()
  gl.attachShader program, vertexShader
  gl.attachShader program, fragmentShader
  gl.linkProgram program

  if ( ! gl.getProgramParameter program, gl.LINK_STATUS )
    status 'Shader link failed'
    return;

  gl.useProgram program

  attribute_names =
    [
      "aVertexPosition",
      "aVertexNormal",
      "aVertexColor",
      "aTextureCoord",
    ]

  program.attributes = []

  for name in attribute_names
    program.attributes[name] = gl.getAttribLocation program, name
    gl.enableVertexAttribArray program.attributes[name]
    console.log name + "=" + program.attributes[name]        

  uniform_names =
    [
      "uPMatrix",
      "uMVMatrix",
      "uNMatrix",
      "uSampler",
      "uUseTexture",
      "uLightDirection",
      "uAmbientColor",
      "uDirectionalColor",
    ]

  program.uniforms = []

  for name in uniform_names
    program.uniforms[name] = gl.getUniformLocation program, name

  return program

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
