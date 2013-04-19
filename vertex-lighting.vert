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

uniform vec3 uLightPosition;

uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;
uniform vec3 uSpecularColor;

void main(void) {
  vec4 mvPosition = uMVMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uPMatrix * mvPosition;

  if ( uUseTexture ) {
    vTextureCoord = aTextureCoord;
  } else {
    vColor = aVertexColor;
  }

  vec3 normal = uNMatrix * aVertexNormal;

  vec3 lightDirection = normalize( uLightPosition - mvPosition.xyz );
  float directionalWeighting = max( dot( normal, lightDirection ), 0.0 );

  vLightWeighting = uAmbientColor + uDirectionalColor * directionalWeighting;
}

