attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec3 aVertexTangent;
attribute vec4 aVertexColor;
attribute vec2 aTextureCoord;
attribute vec2 aNormalCoord;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat3 uNMatrix;
uniform mat4 uProjectionMatrix;

uniform bool uUseTexture;
uniform bool uUseNormalMap;

varying vec4 vColor;
varying vec2 vTextureCoord;
varying vec2 vNormalCoord;

varying vec3 vLightWeighting;

varying vec3 vTransformedNormal;
varying vec3 vTransformedTangent;

varying vec4 vShadowPosition;
varying vec3 vWorldPosition;
varying vec3 vViewPosition;

uniform mat4 uLightPMatrix;
uniform mat4 uLightMVMatrix;

const mat4 cScaleMatrix = mat4(0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.5, 0.0, 0.5, 0.5, 0.5, 1.0);

void main(void) {
  vec4 worldPosition = uModelMatrix * vec4( aVertexPosition, 1.0 );

  vec4 mvPosition = uViewMatrix * worldPosition;
  gl_Position = uProjectionMatrix * mvPosition;

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

  vViewPosition = mvPosition.xyz;
  vWorldPosition = worldPosition.xyz;
  vShadowPosition = cScaleMatrix * uLightPMatrix * uLightMVMatrix * worldPosition;
}

