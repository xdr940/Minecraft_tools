#version 120

#define gbuffers_water
#include "shaders.settings"

varying vec4 color;
varying vec4 ambientNdotL;
varying vec2 texcoord;
varying vec2 lmcoord;
varying vec3 getSunlight;

varying vec3 viewVector;
varying vec3 worldpos;
varying vec3 getShadowPos;
varying float diffuse;
varying mat3 tbnMatrix;

uniform sampler2D noisetex;
uniform sampler2D texture;
uniform sampler2DShadow shadowtex0;
uniform vec3 shadowLightPosition;

uniform float rainStrength;
uniform float frameTimeCounter;

vec4 encode (vec3 n,float dif){
    float p = sqrt(n.z*8+8);
	
	float vis = lmcoord.t;
	if (ambientNdotL.a > 0.9) vis = vis * 0.25;
	if (ambientNdotL.a > 0.4 && ambientNdotL.a < 0.6) vis = vis*0.25+0.25;
	if (ambientNdotL.a < 0.1) vis = vis*0.25+0.5;
		
    return vec4(n.xy/p + 0.5,vis,1.0);
}

mat2 rmatrix(float rad){
	return mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
}

float calcWaves(vec2 coord, float iswater){
	vec2 movement = abs(vec2(0.0, -frameTimeCounter * 0.31365*iswater));

	coord *= 0.262144;
	vec2 coord0 = coord * rmatrix(0.1) - movement;
		 coord0.y *= 3.0;
	vec2 coord1 = coord * rmatrix(-0.5) + movement * 0.9;
		 coord1.y *= 3.0;
	vec2 coord2 = coord + movement * 0.5;
		 coord2.y *= 3.0;
	
	float wave = 1.0 - texture2D(noisetex,coord0 * 0.010416).x * 7.0;
		  wave += 1.0 -texture2D(noisetex,coord1 * 0.010416).x * 10.0;
		  wave += sqrt(texture2D(noisetex,coord2 * 0.0416).x * 6.5) * 1.33;
		  wave *= 0.0157;
	
	return wave;
}

vec3 calcBump(vec2 coord, float iswater){
	const vec2 deltaPos = vec2(0.25, 0.0);

	float h0 = calcWaves(coord, iswater);
	float h1 = calcWaves(coord + deltaPos.xy, iswater);
	float h2 = calcWaves(coord - deltaPos.xy, iswater);
	float h3 = calcWaves(coord + deltaPos.yx, iswater);
	float h4 = calcWaves(coord - deltaPos.yx, iswater);

	float xDelta = ((h1-h0)+(h0-h2));
	float yDelta = ((h3-h0)+(h0-h4));

	return vec3(vec2(xDelta,yDelta)*0.5, 0.5); //z = 1.0-0.5
}

vec3 calcParallax(vec3 pos, float iswater){
	float getwave = calcWaves(pos.xz - pos.y, iswater);

	pos.xz += (getwave * viewVector.xy) * waterheight;
	
	return pos;
}

void main() {

	float iswater = clamp(ambientNdotL.a*2.0-1.0,0.0,1.0);

	vec4 albedo = texture2D(texture, texcoord.xy)*color;
		 albedo.rgb = pow(albedo.rgb,vec3(2.2));
	float texvis = 0.5;

#ifndef watertex
texvis = 0.11;
if(iswater > 0.9)albedo.rgb = vec3(waterCR,waterCG,waterCB);
#endif

	//Bump and parallax mapping
	vec3 waterpos = worldpos;
#ifdef WaterParallax
		 waterpos = calcParallax(waterpos, iswater);
#endif
	vec3 bump = calcBump(waterpos.xz - waterpos.y, iswater);

	vec3 newnormal = normalize(bump * tbnMatrix);
	//---

	//fast shading for translucent blocks
	float NdotL = diffuse;
#ifdef Shadows
	if(NdotL > 0.0 && max(abs(getShadowPos.x),abs(getShadowPos.y)) < 1.0 && rainStrength < 0.9)NdotL *= shadow2D(shadowtex0, getShadowPos.xyz).x;
	NdotL *= (1.0 - iswater);
	NdotL *= (1.0 - rainStrength);
#endif
	vec3 sunlight = getSunlight.rgb*NdotL*(1.0-rainStrength*0.99)*0.85;
	//---

	vec3 fColor = albedo.rgb*(sunlight+ambientNdotL.rgb);
	float alpha = mix(albedo.a,texvis,iswater);
	if(iswater > 0.9)alpha *= waterA;

/* DRAWBUFFERS:526 */
	gl_FragData[0] = vec4(fColor,alpha);
	gl_FragData[1] = encode(newnormal.xyz, NdotL);
	gl_FragData[2] = vec4(normalize(albedo.rgb+0.00001),alpha);
}