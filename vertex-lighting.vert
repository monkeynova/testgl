attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec4 aVertexColor;
attribute vec2 aTextureCoord;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat3 uNMatrix;
uniform mat4 uProjectionMatrix;

uniform bool uUseTexture;

varying vec4 vColor;
varying vec2 vTextureCoord;

varying vec3 vLightWeighting;

uniform vec3 uLightPosition;

uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;
uniform vec3 uSpecularColor;

void main(void) {
  vec4 mvPosition = uViewMatrix * uModelMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uProjectionMatrix * mvPosition;

  if ( uUseTexture ) {
    vTextureCoord = aTextureCoord;
  } else {
    vColor = aVertexColor;
  }

  vec3 normal = uNMatrix * aVertexNormal;

  vec3 lightDirection = normalize( (uViewMatrix * vec4( uLightPosition, 1 )).xyz - mvPosition.xyz );
  float directionalWeighting = max( dot( normal, lightDirection ), 0.0 );

  vLightWeighting = uAmbientColor + uDirectionalColor * directionalWeighting;
}

