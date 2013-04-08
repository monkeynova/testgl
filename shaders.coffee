# -*- Mode: coffee; tab-width: 2; indent-tabs-mode: nil; c-basic-offset: 2 -*-
color_program = null
texture_program = null

initShaders = (gl) ->
  color_program = initColorShader gl
  texture_program = initTextureShader gl

initColorShader = (gl) ->
  program = null

  fragmentShader = getShader gl, 'color-fs'
  vertexShader = getShader gl, 'color-vs'

  program = gl.createProgram()
  gl.attachShader program, vertexShader
  gl.attachShader program, fragmentShader
  gl.linkProgram program

  if ( ! gl.getProgramParameter program, gl.LINK_STATUS )
    status 'Shader link failed'
    return;

  gl.useProgram program
  program.vertexPositionAttribute = gl.getAttribLocation program, "aVertexPosition"
  gl.enableVertexAttribArray program.vertexPositionAttribute

  program.vertexColorAttribute = gl.getAttribLocation program, "aVertexColor"
  gl.enableVertexAttribArray program.vertexColorAttribute

  program.pMatrixUniform = gl.getUniformLocation program, "uPMatrix"
  program.mvMatrixUniform = gl.getUniformLocation program, "uMVMatrix"

  return program

initTextureShader = (gl) ->
  program = null

  fragmentShader = getShader gl, 'texture-fs'
  vertexShader = getShader gl, 'texture-vs'

  program = gl.createProgram()
  gl.attachShader program, vertexShader
  gl.attachShader program, fragmentShader
  gl.linkProgram program

  if ( ! gl.getProgramParameter program, gl.LINK_STATUS )
    status 'Shader link failed'
    return;

  gl.useProgram program
  program.vertexPositionAttribute = gl.getAttribLocation program, "aVertexPosition"
  gl.enableVertexAttribArray program.vertexPositionAttribute

  program.vertexTextureAttribute = gl.getAttribLocation program, "aTextureCoord"
  gl.enableVertexAttribArray program.vertexColorAttribute

  program.samplerUniform = gl.getUniformLocation program, "uSampler"

  program.pMatrixUniform = gl.getUniformLocation program, "uPMatrix"
  program.mvMatrixUniform = gl.getUniformLocation program, "uMVMatrix"

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
