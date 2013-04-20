precision mediump float;

varying vec4 vPosition;

void main(void) {
  float dist = length( vPosition ) / 200.0;

  gl_FragColor = vec4(
                      dist,
                      floor( dist * 256.0 ),
                      floor( dist * 256.0 * 256.0 ),
                      floor( dist * 256.0 * 256.0 * 256.0 )
                      );
}
