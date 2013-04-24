precision mediump float;

varying vec3 vLightWeighting;

varying vec4 vColor;
varying vec2 vTextureCoord;

uniform bool uUseTexture;

uniform sampler2D uTextureSampler;

void main(void) {
  vec4 color;
  if ( uUseTexture ) {
    color = texture2D(uTextureSampler,vec2(vTextureCoord.x,vTextureCoord.y));
  }
  else {
    color = vColor;
  }

  vec4 surfaceColor = vec4( color.rgb * vLightWeighting, color.a );

  if ( false ) {
    float dist = 1.0 - gl_FragCoord.z * gl_FragCoord.w;
    vec4 fogColor = 0.2 * dist * vec4( 1, 1, 1, 1 );

    gl_FragColor = fogColor + surfaceColor;

  } else {
    gl_FragColor = surfaceColor;

  }
}
