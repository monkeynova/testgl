attribute vec3 aVertexPosition;

uniform mat4 uModelMatrix;
uniform mat4 uViewMatrix;
uniform mat4 uProjectionMatrix;

varying vec4 vPosition;

void main(void) {
  vPosition = uViewMatrix * uModelMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uProjectionMatrix * vPosition;
}

