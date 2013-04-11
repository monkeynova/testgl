attribute vec3 aVertexPosition;
attribute vec3 aVertexNormal;
attribute vec4 aVertexColor;
attribute vec2 aTextureCoord;

uniform mat4 uMVMatrix;
uniform mat3 uNMatrix;
uniform mat4 uPMatrix;

uniform vec3 uLightPosition;
uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;

uniform bool uUseTexture;

varying vec4 vColor;
varying vec2 vTextureCoord;

varying vec3 vLightWeighting;

void main(void) {
  vec4 mvPosition = uMVMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uPMatrix * mvPosition;

  if ( uUseTexture ) {
    vTextureCoord = aTextureCoord;
  } else {
    vColor = aVertexColor;
  }

  vec3 lightDirection = normalize( uLightPosition - mvPosition.xyz );
  vec3 transformedNormal = uNMatrix * aVertexNormal;
  float lightWeighting = max( dot( transformedNormal, lightDirection ), 0.0 );

  vLightWeighting = uAmbientColor + uDirectionalColor * lightWeighting;
}

