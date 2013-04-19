precision mediump float;

varying vec4 mvPosition;

void main(void) {
  gl_FragColor = vec4( mvPosition.z, 0, 0, 1 );
}
