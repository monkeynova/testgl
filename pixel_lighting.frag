precision mediump float;

varying vec3 vLightWeighting;

varying vec4 vColor;
varying vec2 vTextureCoord;
varying vec2 vNormalCoord;

uniform bool uUseTexture;
uniform bool uUseNormalMap;

uniform vec3 uLightPosition;

uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;
uniform vec3 uSpecularColor;

uniform float uMaterialShininess;

uniform sampler2D uTextureSampler;
uniform sampler2D uNormalSampler;

varying vec3 vPosition;
varying vec3 vTransformedNormal;

void main(void) {
  vec4 color;
  if ( uUseTexture ) {
    color = texture2D( uTextureSampler, vec2( vTextureCoord.x, vTextureCoord.y ) );
  } else {
    color = vColor;
  }

  vec3 normal;

  if ( uUseNormalMap ) {
    normal = texture2D( uNormalSampler, vec2( vNormalCoord.x, vNormalCoord.y ) ).xyz * 2.0 - 1.0;
  } else {
    normal = normalize( vTransformedNormal );
  }

  vec3 lightDirection = normalize( uLightPosition - vPosition );

  float specularLighting = 0.0;

  if ( uMaterialShininess != 0.0 ) {
    vec3 eyeDirection = normalize( -vPosition );
    vec3 reflectDirection = reflect( -lightDirection, normal );
    specularLighting = pow( max( dot( reflectDirection, eyeDirection ), 0.0 ), uMaterialShininess );
  }

  float lightWeighting = max( dot( normal, lightDirection ), 0.0 );
  vec3 lightColor = uAmbientColor + uDirectionalColor * lightWeighting + uSpecularColor * specularLighting;

  vec4 surfaceColor = vec4( color.rgb * lightColor, color.a );

  if ( false ) {
    float dist = 1.0 - gl_FragCoord.z * gl_FragCoord.w;
    vec4 fogColor = 0.2 * dist * vec4( 1, 1, 1, 1 );

    gl_FragColor = fogColor + surfaceColor;

  } else {
    gl_FragColor = surfaceColor;

  }
}
