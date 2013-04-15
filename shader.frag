precision mediump float;

varying vec3 vLightWeighting;

varying vec4 vColor;
varying vec2 vTextureCoord;

uniform bool uUseTexture;

uniform vec3 uLightPosition;

uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;

uniform sampler2D uSampler;

varying vec3 vPosition;
varying vec3 vTransformedNormal;

void main(void) {
  vec4 color;
  if ( uUseTexture ) {
    color = texture2D(uSampler,vec2(vTextureCoord.x,vTextureCoord.y));
  }
  else {
    color = vColor;
  }

  vec3 lightDirection = normalize( uLightPosition - vPosition );
  float lightWeighting = max( dot( normalize( vTransformedNormal ), lightDirection ), 0.0 );
  vec3 lightColor = uAmbientColor + uDirectionalColor * lightWeighting;

  vec4 surfaceColor = vec4( color.rgb * lightColor, color.a );

  if ( false ) {
    float dist = 1.0 - gl_FragCoord.z * gl_FragCoord.w;
    vec4 fogColor = 0.2 * dist * vec4( 1, 1, 1, 1 );

    gl_FragColor = fogColor + surfaceColor;

  } else {
    gl_FragColor = surfaceColor;

  }
}
