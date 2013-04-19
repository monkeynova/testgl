precision mediump float;

varying vec3 vLightWeighting;

varying vec4 vColor;
varying vec2 vTextureCoord;
varying vec2 vNormalCoord;

uniform bool uUseTexture;
uniform bool uUseNormalMap;
uniform bool uUseShadowTexture;

uniform mat4 uLightPMatrix;
uniform mat4 uLightMVMatrix;

uniform vec3 uLightPosition;

uniform vec3 uAmbientColor;
uniform vec3 uDirectionalColor;
uniform vec3 uSpecularColor;

uniform float uMaterialShininess;

uniform mat4 uViewMatrix;

uniform sampler2D uTextureSampler;
uniform sampler2D uNormalSampler;
uniform sampler2D uShadowSampler;

varying vec3 vViewPosition;
varying vec3 vWorldPosition;
varying vec3 vTransformedNormal;
varying vec3 vTransformedTangent;

void main(void) {
  vec4 color;
  if ( uUseTexture ) {
    color = texture2D( uTextureSampler, vec2( vTextureCoord.x, vTextureCoord.y ) );
  } else {
    color = vColor;
  }

  vec3 normal;

  if ( uUseNormalMap ) {
    vec3 textureNormal = texture2D( uNormalSampler, vec2( vNormalCoord.x, vNormalCoord.y ) ).xyz * 2.0 - 1.0;

    vec3 binormal = cross( vTransformedTangent, vTransformedNormal );

    normal = textureNormal.x * vTransformedTangent +
      textureNormal.y * binormal +
      textureNormal.z * vTransformedNormal;

    normal = normalize( normal );
  } else {
    normal = normalize( vTransformedNormal );
  }

  vec3 toLight = (uViewMatrix * vec4( uLightPosition, 1 ) ).xyz - vViewPosition;
  bool inShadow = false;

  if ( uUseShadowTexture ) {
    float lightDistance = length( toLight );

    vec4 projectedLight = uLightPMatrix * uLightMVMatrix * vec4( -toLight, 1 );

    vec4 shadowDistanceColor = texture2D( uShadowSampler, projectedLight.xy / projectedLight.w );

    gl_FragColor = shadowDistanceColor;
    return;

    float shadowDistance = shadowDistanceColor.r +
      shadowDistanceColor.g / 256.0 +
      shadowDistanceColor.b / (256.0 * 256.0) +
      shadowDistanceColor.a / (256.0 * 256.0 * 256.0);

    if ( shadowDistance < lightDistance ) {
      inShadow = true;
    }
  }

  float lightWeighting = 0.0;
  float specularLighting = 0.0;

  if ( ! inShadow ) {
    vec3 lightDirection = normalize( toLight );

    if ( uMaterialShininess != 0.0 ) {
      vec3 eyeDirection = normalize( -vViewPosition );
      vec3 reflectDirection = reflect( -lightDirection, normal );
      specularLighting = pow( max( dot( reflectDirection, eyeDirection ), 0.0 ), uMaterialShininess );
    }

    lightWeighting = max( dot( normal, lightDirection ), 0.0 );
  }

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
