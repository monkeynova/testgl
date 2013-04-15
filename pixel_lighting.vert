attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec4 aVertexColor;
attribute vec2 aTextureCoord;

uniform mat4 uMVMatrix;
uniform mat3 uNMatrix;
uniform mat4 uPMatrix;

uniform bool uUseTexture;

varying vec4 vColor;
varying vec2 vTextureCoord;

varying vec3 vLightWeighting;

varying vec3 vPosition;
varying vec3 vTransformedNormal;

void main(void) {
  vec4 mvPosition = uMVMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uPMatrix * mvPosition;

  if ( uUseTexture ) {
    vTextureCoord = aTextureCoord;
  } else {
    vColor = aVertexColor;
  }

  vPosition = mvPosition.xyz;
  vTransformedNormal = uNMatrix * aVertexNormal;
}

