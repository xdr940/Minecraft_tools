#version 120
/*
Sildur's vibrant shaders, before editing, remember the agreement you've accepted by downloading this shaderpack:
http://www.minecraftforum.net/forums/mapping-and-modding/minecraft-mods/1291396-1-6-4-1-12-1-sildurs-shaders-pc-mac-intel

You are allowed to:
- Modify it for your own personal use only, so don't share it online.

You are not allowed to:
- Rename and/or modify this shaderpack and upload it with your own name on it.
- Provide mirrors by reuploading my shaderpack, if you want to link it, use the link to my thread found above.
- Copy and paste code or even whole files into your "own" shaderpack.
*/
#define emissive_R 1.5		//[0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define emissive_G 0.42		//[0.0 0.1 0.2 0.3 0.42 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define emissive_B 0.045	//[0.0 0.045 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0 1.1 1.2 1.3 1.4 1.5 1.6 1.7 1.8 1.9 2.0]
#define minlight 0.002		//[0.002 0.004 0.006 0.008 0.01] Tweak the amount of minimal light inside caves etc.

varying vec4 color;
varying vec2 texcoord;
varying vec3 normal;
varying vec3 ambientNdotL;
varying vec3 finalSunlight;
varying float skyL;

uniform vec3 sunPosition;
uniform vec3 upPosition;

uniform int worldTime;
uniform float rainStrength;
uniform float nightVision;

const vec3 ToD[7] = vec3[7](  vec3(0.58597,0.15,0.02),
								vec3(0.58597,0.35,0.09),
								vec3(0.58597,0.5,0.26),
								vec3(0.58597,0.5,0.35),
								vec3(0.58597,0.5,0.36),
								vec3(0.58597,0.5,0.37),
								vec3(0.58597,0.5,0.38));
								

void main() {

	//setup basics
	color = gl_Color;
	gl_Position = ftransform();
	
	normal = normalize(gl_NormalMatrix * gl_Normal);	
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	vec2 lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	/*--------------------------------*/
	
	//Emissive blocks lighting in order to fix lighting on particles
	float torch_lightmap = 16.0-min(15.,(lmcoord.s-0.5/16.)*16.*16./15);
	float fallof1 = clamp(1.0 - pow(torch_lightmap/16.0,4.0),0.0,1.0);
	torch_lightmap = fallof1*fallof1/(torch_lightmap*torch_lightmap+1.0);
	vec3 emissiveLightC = vec3(emissive_R,emissive_G,emissive_B)*torch_lightmap;
	float finalminlight = (nightVision > 0.9)? 0.025 : minlight;
	/*---------------------------------------------------------------------*/
	
	//reduced the sun color to a 7 array
	float hour = max(mod(worldTime/1000.0+2.0,24.0)-2.0,0.0);  //-0.1
	float cmpH = max(-abs(floor(hour)-6.0)+6.0,0.0); //12
	float cmpH1 = max(-abs(floor(hour)-5.0)+6.0,0.0); //1
	
	vec3 temp = ToD[int(cmpH)];
	vec3 temp2 = ToD[int(cmpH1)];
	
	vec3 sunlight = mix(temp,temp2,fract(hour));
	const vec3 rainC = vec3(0.01,0.01,0.01);
	sunlight = mix(sunlight,rainC*sunlight,rainStrength);
	/*-------------------------------------------------------------------*/	
	
	const vec3 moonlight = vec3(0.0024, 0.00432, 0.0078);

	vec3 sunVec = normalize(sunPosition);
	vec3 upVec = normalize(upPosition);

	vec2 visibility = vec2(dot(sunVec,upVec),dot(-sunVec,upVec));

	float NdotL = dot(normal,sunVec);
	float NdotU = dot(normal,upVec);

	vec2 trCalc = min(abs(worldTime-vec2(23250.0,12700.0)),750.0);
	float tr = max(min(trCalc.x,trCalc.y)/375.0-1.0,0.0);
	visibility = pow(clamp(visibility+0.15,0.0,0.15)/0.15,vec2(4.0));

	skyL = max(lmcoord.t-2./16.0,0.0)*1.14285714286;
	float SkyL2 = skyL*skyL;
	float skyc2 = mix(1.0,SkyL2,skyL);
	
	vec4 bounced = vec4(NdotL,NdotL,NdotL,NdotU) * vec4(-0.14*skyL*skyL,0.34,0.7,0.1) + vec4(0.6,0.66,0.7,0.25);
	bounced *= vec4(skyc2,skyc2,visibility.x-tr*visibility.x,0.8);

	vec3 sun_ambient = bounced.w * (vec3(0.1, 0.5, 1.1)+rainStrength*vec3(0.05,-0.27,-0.8))*2.3+ 1.7*sunlight*(sqrt(bounced.w)*bounced.x*2.4 + bounced.z)*(1.0-rainStrength*0.98);
	vec3 moon_ambient = (moonlight*0.7 + moonlight*bounced.y)*(1.0-rainStrength*0.95)*2.0;
	
	vec3 amb1 = (sun_ambient*visibility.x + moon_ambient*visibility.y)*SkyL2*(0.03+tr*0.17)*0.65;
	ambientNdotL.rgb =  amb1 + emissiveLightC + finalminlight;

	sunlight = mix(sunlight,moonlight*(1.0-rainStrength*0.9),visibility.y)*tr;
	
	finalSunlight = sunlight*0.9;

}