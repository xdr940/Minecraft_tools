#version 120
/* DRAWBUFFERS:56 */
//Render hand, entities and particles in here, boost and fix enchanted armor effect in gbuffers_armor_glint
#define gbuffers_texturedblock
#include "shaders.settings"

varying vec4 color;
varying vec2 texcoord;
varying vec3 normal;
varying vec3 ambientNdotL;
varying vec3 finalSunlight;
varying float skyL;
#ifdef Shadows
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform sampler2DShadow shadow;
#endif
uniform sampler2D texture;

uniform float viewWidth;
uniform float viewHeight;
uniform vec4 entityColor;
uniform float rainStrength;

uniform vec3 shadowLightPosition;
uniform int worldTime;
uniform ivec2 eyeBrightnessSmooth;

void main() {

	float diffuse = clamp(dot(normalize(shadowLightPosition),normal),0.0,1.0);
	
	vec4 albedo = texture2D(texture, texcoord.xy)*color;
#ifdef MobsFlashRed
	albedo.rgb = mix(albedo.rgb,entityColor.rgb,entityColor.a);
#endif

#ifdef Shadows
#define diagonal3(mat) vec3((mat)[0].x, (mat)[1].y, (mat)[2].z)
//don't do shading if transparent/translucent (not opaque)
if (diffuse > 0.0 && rainStrength < 0.9 && albedo.a > 0.01){
vec4 fragposition = gbufferProjectionInverse*(vec4(gl_FragCoord.xy/vec2(viewWidth,viewHeight),gl_FragCoord.z,1.0)*2.0-1.0);
	 fragposition.xyz /= fragposition.w;

	vec3 worldposition = mat3(gbufferModelViewInverse) * fragposition.xyz + gbufferModelViewInverse[3].xyz;
		 worldposition = mat3(shadowModelView) * worldposition.xyz + shadowModelView[3].xyz;
		 worldposition = diagonal3(shadowProjection) * worldposition.xyz + shadowProjection[3].xyz;
	
	float distortion = ((1.0 - SHADOW_MAP_BIAS) + length(worldposition.xy * 1.165) * SHADOW_MAP_BIAS) * 0.97;
	float bias = distortion*distortion*(0.005*tan(acos(diffuse)));
	worldposition.xy /= distortion;
	worldposition.xyz = worldposition.xyz * 0.5 + 0.5;
	worldposition.z -= bias;

	//Fast and simple shadow drawing for proper rendering of entities etc
	diffuse *= shadow2D(shadow, worldposition.xyz).x;
	diffuse *= (1.0 - rainStrength);
	diffuse *= mix(skyL,1.0,clamp((eyeBrightnessSmooth.y/255.0-2.0/16.)*4.0,0.0,1.0)); //avoid light leaking underground	
}
#endif

	vec3 finalColor = pow(albedo.rgb,vec3(2.2)) * (finalSunlight*diffuse+ambientNdotL.rgb);

	gl_FragData[0] = vec4(finalColor, albedo.a);
	gl_FragData[1] = vec4(normalize(albedo.rgb+0.00001), albedo.a);		
}