precision mediump float;

varying vec2 vTextureCoord;
uniform sampler2D uTextureSampler;

void main(void) {
  gl_FragColor = texture2D(uTextureSampler,vec2(vTextureCoord.x,vTextureCoord.y));
}
