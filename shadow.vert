attribute vec3 aVertexPosition;

uniform mat4 uMVMatrix;
uniform mat4 uPMatrix;

varying vec4 vPosition;

void main(void) {
  vPosition = uMVMatrix * vec4( aVertexPosition, 1.0 );
  gl_Position = uPMatrix * vPosition;
}

