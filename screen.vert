attribute vec2 aVertexPosition;
attribute vec2 aTextureCoord;

varying vec2 vTextureCoord;

uniform vec2 u2DOffset;
uniform vec2 u2DStride;

void main(void) {
  vTextureCoord = aTextureCoord;
  gl_Position = vec4( aVertexPosition * u2DStride + u2DOffset, 0.1, 1 );
}

