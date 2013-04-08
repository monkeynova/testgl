precision mediump float;

varying vec3 vLightWeighting;

varying vec4 vColor;
varying vec2 vTextureCoord;

uniform bool uUseTexture;

uniform sampler2D uSampler;

void main(void) {
  vec4 color;
  if ( uUseTexture ) {
    color = texture2D(uSampler,vec2(vTextureCoord.x,vTextureCoord.y));
  }
  else {
    color = vColor;
  }
  gl_FragColor = vec4( color.rgb * vLightWeighting, color.a );
}
