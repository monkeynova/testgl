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

  program.vertexPositionAttribute = gl.getAttribLocation program, "aVertexPosition"
  console.log "aVertexPosition=" + program.vertexPositionAttribute
  gl.enableVertexAttribArray program.vertexPositionAttribute

  program.vertexNormalAttribute = gl.getAttribLocation program, "aVertexNormal"
  console.log "aVertexNormal=" + program.vertexNormalAttribute
  gl.enableVertexAttribArray program.vertexNormalAttribute

  program.vertexColorAttribute = gl.getAttribLocation program, "aVertexColor"
  console.log "aVertexColor=" + program.vertexColorAttribute
  gl.enableVertexAttribArray program.vertexColorAttribute

  program.vertexTextureAttribute = gl.getAttribLocation program, "aTextureCoord"
  console.log "aTextureCoord=" + program.vertexTextureAttribute
  gl.enableVertexAttribArray program.vertexTextureAttribute

  program.pMatrixUniform = gl.getUniformLocation program, "uPMatrix"
  program.mvMatrixUniform = gl.getUniformLocation program, "uMVMatrix"
  program.nMatrixUniform = gl.getUniformLocation program, "uNMatrix"

  program.samplerUniform = gl.getUniformLocation program, "uSampler"
  program.useTextureUniform = gl.getUniformLocation program, "uUseTexture"

  program.lightDirectionUniform = gl.getUniformLocation program, "uLightDirection"
  program.ambientColorUniform = gl.getUniformLocation program, "uAmbientColor"
  program.directionalColorUniform = gl.getUniformLocation program, "uDirectionalColor"

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
