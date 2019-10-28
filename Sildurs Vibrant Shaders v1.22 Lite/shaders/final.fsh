#version 120

#define final
#include "shaders.settings"

varying vec2 texcoord;
uniform sampler2D composite;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform int isEyeInWater;

uniform float aspectRatio;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;

#ifdef Rain_Drops
varying vec2 rainPos1;
varying vec2 rainPos2;
varying vec2 rainPos3;
varying vec2 rainPos4;
varying vec4 weights;
#endif

#if defined Depth_of_Field || defined Motionblur || defined Cloudsblur
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
#endif

#ifdef Motionblur
uniform vec3 cameraPosition; 
uniform vec3 previousCameraPosition;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
#endif

#if defined Depth_of_Field || defined Cloudsblur
uniform float near;
uniform float far;
float ld(float depth) {
    return (2.0 * near) / (far + near - depth * (far - near));
}
#endif

#ifdef Depth_of_Field
//Dof constant values
const float focal = 0.024;
float aperture = 0.008;	
const float sizemult = DoF_Strength;

	//hexagon pattern
	const vec2 hex_offsets[60] = vec2[60] (	vec2(  0.2165,  0.1250 ),
											vec2(  0.0000,  0.2500 ),
											vec2( -0.2165,  0.1250 ),
											vec2( -0.2165, -0.1250 ),
											vec2( -0.0000, -0.2500 ),
											vec2(  0.2165, -0.1250 ),
											vec2(  0.4330,  0.2500 ),
											vec2(  0.0000,  0.5000 ),
											vec2( -0.4330,  0.2500 ),
											vec2( -0.4330, -0.2500 ),
											vec2( -0.0000, -0.5000 ),
											vec2(  0.4330, -0.2500 ),
											vec2(  0.6495,  0.3750 ),
											vec2(  0.0000,  0.7500 ),
											vec2( -0.6495,  0.3750 ),
											vec2( -0.6495, -0.3750 ),
											vec2( -0.0000, -0.7500 ),
											vec2(  0.6495, -0.3750 ),
											vec2(  0.8660,  0.5000 ),
											vec2(  0.0000,  1.0000 ),
											vec2( -0.8660,  0.5000 ),
											vec2( -0.8660, -0.5000 ),
											vec2( -0.0000, -1.0000 ),
											vec2(  0.8660, -0.5000 ),
											vec2(  0.2163,  0.3754 ),
											vec2( -0.2170,  0.3750 ),
											vec2( -0.4333, -0.0004 ),
											vec2( -0.2163, -0.3754 ),
											vec2(  0.2170, -0.3750 ),
											vec2(  0.4333,  0.0004 ),
											vec2(  0.4328,  0.5004 ),
											vec2( -0.2170,  0.6250 ),
											vec2( -0.6498,  0.1246 ),
											vec2( -0.4328, -0.5004 ),
											vec2(  0.2170, -0.6250 ),
											vec2(  0.6498, -0.1246 ),
											vec2(  0.6493,  0.6254 ),
											vec2( -0.2170,  0.8750 ),
											vec2( -0.8663,  0.2496 ),
											vec2( -0.6493, -0.6254 ),
											vec2(  0.2170, -0.8750 ),
											vec2(  0.8663, -0.2496 ),
											vec2(  0.2160,  0.6259 ),
											vec2( -0.4340,  0.5000 ),
											vec2( -0.6500, -0.1259 ),
											vec2( -0.2160, -0.6259 ),
											vec2(  0.4340, -0.5000 ),
											vec2(  0.6500,  0.1259 ),
											vec2(  0.4325,  0.7509 ),
											vec2( -0.4340,  0.7500 ),
											vec2( -0.8665, -0.0009 ),
											vec2( -0.4325, -0.7509 ),
											vec2(  0.4340, -0.7500 ),
											vec2(  0.8665,  0.0009 ),
											vec2(  0.2158,  0.8763 ),
											vec2( -0.6510,  0.6250 ),
											vec2( -0.8668, -0.2513 ),
											vec2( -0.2158, -0.8763 ),
											vec2(  0.6510, -0.6250 ),
											vec2(  0.8668,  0.2513 ));								
#endif

#ifdef Cloudsblur
float comp = 1.0-near/far/far;
vec3 cblur(vec2 tc){
	float pw = 1.0 / viewWidth;
	float getdist = 1.0-(exp(-pow(ld(texture2D(depthtex1, tc).r)/256.0*far,4.0)*4.0));
	float pcoc = min(getdist*pw*20.0,pw*20.0);
	vec2 fast_blur[4] = vec2[4](vec2(0.0, -0.1),
								vec2(-0.1, 0.0),
								vec2(0.1, 0.0),
								vec2(0.0, 0.1));
	vec3 blurC = vec3(0.0);
	for (int i = 0; i < 4; i++) {
		blurC += texture2D(composite, tc + fast_blur[i]*pcoc*vec2(1.0,aspectRatio)).rgb;
	}
		blurC = blurC/4.0*50.0;

	return blurC;
}
#endif

#ifdef Rain_Drops
float distratio(vec2 pos, vec2 pos2) {
	return distance(pos*vec2(aspectRatio,1.0),pos2*vec2(aspectRatio,1.0));
}
float gen_circular_lens(vec2 center, float size) {
	float dist=distratio(center,texcoord.xy)/size;
	return exp(-dist*dist);
}
#endif

vec3 Uncharted2Tonemap(vec3 x) {
	x*= Brightness;
	float A = 0.28;
	float B = 0.29;		
	float C = 0.10;
	float D = 0.2;
	float E = 0.025;
	float F = 0.35;
	return ((x*(A*x+C*B)+D*E)/(x*(A*x+B)+D*F))-E/F;
}

void main() {

#if defined Depth_of_Field || defined Motionblur || defined Cloudsblur
//Setup depths, do it here because amd drivers suck and texture reads outside of void main or functions are broken, thanks amd
float depth0 = texture2D(depthtex0, texcoord).x;
float depth1 = texture2D(depthtex1, texcoord).x;
float depth2 = texture2D(depthtex2, texcoord).x;
bool hand = (depth0 < depth1) || !(depth0 < depth2);
#endif

//Rainlens
float rainlens = 0.0;
#ifdef Rain_Drops	
	if (rainStrength > 0.02) {
		rainlens += gen_circular_lens(rainPos1,0.1)*weights.x;
		rainlens += gen_circular_lens(rainPos2,0.07)*weights.y;
		rainlens += gen_circular_lens(rainPos3,0.086)*weights.z;
		rainlens += gen_circular_lens(rainPos4,0.092)*weights.w;
	}/*----------------------------------------------------------*/
#endif

	vec2 fake_refract = vec2(sin(frameTimeCounter + texcoord.x*100.0 + texcoord.y*50.0),cos(frameTimeCounter + texcoord.y*100.0 + texcoord.x*50.0)) ;
	vec2 newTC = clamp(texcoord + fake_refract * 0.01 * (rainlens+isEyeInWater*0.2),1.0/vec2(viewWidth,viewHeight),1.0-1.0/vec2(viewWidth,viewHeight));
	vec3 color = texture2D(composite, newTC.xy).rgb*50.0;
	vec3 blur = texture2D(gaux4, texcoord.xy/4.0).rgb;
#ifdef Cloudsblur
#ifdef MC_GL_VENDOR_ATI
	color.rgb = cblur(newTC.xy);	//checking only for sky causes weird outlines on amd cards
#else
	if(depth1 > comp)color.rgb = cblur(newTC.xy);
#endif	
#endif

#ifdef Depth_of_Field
if(hand){
	float pw = 1.0/ viewWidth;
	float z = ld(texture2D(depthtex0, newTC.st).r)*far;
	float focus = ld(texture2D(depthtex0, vec2(0.5)).r)*far;
	float pcoc = min(abs(aperture * (focal * (z - focus)) / (z * (focus - focal)))*sizemult,pw*15.0);
#ifdef Distance_Blur
	float getdist = 1-(exp(-pow(ld(texture2D(depthtex1, newTC.st).r)/Dof_Distance_View*far,4.0-(2.7*rainStrength))*4.0));	
	pcoc = min(getdist*pw*20.0,pw*20.0);
#endif
	vec3 bcolor = vec3(0.0);
		for ( int i = 0; i < 60; i++) {
			bcolor += texture2D(composite, newTC.xy + hex_offsets[i]*pcoc*vec2(1.0,aspectRatio)).rgb;
			}
		color.rgb = bcolor/61.0*50.0;
}
#endif
	

#ifdef Motionblur
if(hand){
	vec4 currentPosition = vec4(texcoord, depth1, 1.0)*2.0-1.0;
	
	vec4 fragposition = gbufferProjectionInverse * currentPosition;
		 fragposition = gbufferModelViewInverse * fragposition;
		 fragposition /= fragposition.w;
		 fragposition.xyz += cameraPosition;
	
	vec4 previousPosition = fragposition;
		 previousPosition.xyz -= previousCameraPosition;
		 previousPosition = gbufferPreviousModelView * previousPosition;
		 previousPosition = gbufferPreviousProjection * previousPosition;
		 previousPosition /= previousPosition.w;

	vec2 velocity = (currentPosition - previousPosition).st * MB_strength;
	vec2 coord = texcoord.st + velocity;

	int mb = 1;
	for (int i = 0; i < 15; ++i, coord += velocity) {
		if (coord.s > 1.0 || coord.t > 1.0 || coord.s < 0.0 || coord.t < 0.0) break;
		color += texture2D(composite, coord).xyz*50.0;
		++mb;
	}
	color /= mb;
}
#endif

	color.rgb += blur;
	color.rgb += rainlens*0.01; //draw rainlens
	
	vec3 curr = Uncharted2Tonemap(color*4.7);
	color = pow(curr/Uncharted2Tonemap(vec3(15.2)),vec3(1.0/Contrast));

	gl_FragColor = vec4(color,1.0);
}
