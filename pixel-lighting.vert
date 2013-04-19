attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec3 aVertexTangent;
attribute vec4 aVertexColor;
attribute vec2 aTextureCoord;
attribute vec2 aNormalCoord;

uniform mat4 uMVMatrix;
uniform mat3 uNMatrix;
uniform mat4 uPMatrix;

uniform bool uUseTexture;
uniform bool uUseNormalMap;

varying vec4 vColor;
varying vec2 vTextureCoord;
varying vec2 vNormalCoord;

varying vec3 vLightWeighting;

varying vec3 vPosition;
varying vec3 vTransformedNormal;
varying vec3 vTransformedTangent;

void main(void) {
  vec4 mvPosition = uMVMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uPMatrix * mvPosition;

  if ( uUseTexture ) {
    vTextureCoord = aTextureCoord;
  } else {
    vColor = aVertexColor;
  }

  if ( uUseNormalMap ) {
    vNormalCoord = aNormalCoord;
    vTransformedTangent = uNMatrix * aVertexTangent;
  }

  vTransformedNormal = uNMatrix * aVertexNormal;

  vPosition = mvPosition.xyz;
}

