#version 120
#extension GL_ARB_shader_texture_lod : enable
const bool gaux1MipmapEnabled = true;
/* DRAWBUFFERS:3 */

#define composite1
#include "shaders.settings"

//custom uniforms defined in shaders.properties
uniform float inSwamp;
uniform float BiomeTemp;

varying vec2 texcoord;
varying vec2 lightPos;

varying vec3 sunVec;
varying vec3 upVec;
varying vec3 lightColor;
varying vec3 sky1;
varying vec3 sky2;
varying vec3 nsunlight;
varying vec3 sunlight;
const vec3 moonlight = vec3(0.0025, 0.0045, 0.007);
varying vec3 rawAvg;
varying vec3 avgAmbient2;
varying vec3 cloudColor;
varying vec3 cloudColor2;

varying float fading;
varying float tr;
varying float eyeAdapt;
varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

uniform sampler2D composite;
uniform sampler2D gaux1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D gnormal;
uniform sampler2D gdepth;

uniform sampler2D noisetex;
uniform sampler2D gaux3;
uniform sampler2D gaux2;
uniform sampler2D gaux4;

uniform vec3 cameraPosition;
uniform vec3 sunPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

uniform ivec2 eyeBrightness;
uniform ivec2 eyeBrightnessSmooth;
uniform int isEyeInWater;
uniform int worldTime;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float blindness;

/*------------------------------------------*/
float comp = 1.0-near/far/far;
float tmult = mix(min(abs(worldTime-6000.0)/6000.0,1.0),1.0,rainStrength);
float night = clamp((worldTime-13000.0)/300.0,0.0,1.0)-clamp((worldTime-22800.0)/200.0,0.0,1.0);

//Draw sun and moon
vec3 drawSun(vec3 fposition, vec3 color, float vis) {
	vec3 sVector = normalize(fposition);
	float angle = (1.0-max(dot(sVector,sunVec),0.0))* 650.0;
	float sun = exp(-angle*angle*angle);
			sun *= (1.0-rainStrength*1.0)*sunVisibility;
	vec3 sunlightB = mix(pow(sunlight,vec3(1.0))*44.0,vec3(0.25,0.3,0.4),rainStrength*0.8);

	return mix(color,sunlightB,sun*vis);
}
vec3 drawMoon(vec3 fposition, vec3 color, float vis) {
	vec3 sVector = normalize(fposition);
	float angle = (1.0-max(dot(sVector,-sunVec),0.0))* 2000.0;
	float moon = exp(-angle*angle*angle);
			moon *= (1.0-rainStrength*1.0)*moonVisibility;
	vec3 moonlightC = mix(pow(moonlight*40.0,vec3(1.0))*44.0,vec3(0.25,0.3,0.4),rainStrength*0.8);

	return mix(color,moonlightC,moon*vis);
}/**--------------------------------------*/

#ifdef Fog
float getAirDensity (float h) {
	return max(h/10.,6.0);
}

float calcFog(vec3 fposition) {
	float density = wFogDensity*(1.0-rainStrength*0.115);

	vec3 worldpos = (gbufferModelViewInverse*vec4(fposition,1.0)).rgb+cameraPosition;
	float height = mix(getAirDensity (worldpos.y),6.,rainStrength);
	float d = length(fposition);

	return pow(clamp((2.625+rainStrength*3.4)/exp(-60/10./density)*exp(-getAirDensity (cameraPosition.y)/density) * (1.0-exp( -pow(d,2.712)*height/density/(6000.-tmult*tmult*2000.)/13))/height,0.0,1.),1.0-rainStrength*0.63)*clamp((eyeBrightnessSmooth.y/255.-2/16.)*4.,0.0,1.0);
}
#else
float calcFog(vec3 fposition) {
	return 0.0;
}
#endif

//Skycolor
vec3 getSkyc(vec3 fposition) {
vec3 sVector = normalize(fposition);

float invRain07 = 1.0-rainStrength*0.6;
float cosT = dot(sVector,upVec);
float mCosT = max(cosT,0.0);
float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
float cosY = dot(sunVec,sVector);
float Y = acos(cosY);

const float a = -1.;
const float b = -0.22;
const float c = 8.0;
const float d = -3.5;
const float e = 0.3;

//luminance
float L =  (1.0+a*exp(b/(mCosT)));
float A = 1.0+e*cosY*cosY;

//gradient
vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
float sunscat = max(cosY,0.0);
vec3 grad3 = mix(grad1,nsunlight,sunscat*sunscat*(1.0-mCosT)*(0.9-rainStrength*0.5*0.9)*(clamp(-(SdotU)*4.0+3.0,0.0,1.0)*0.65+0.35)+0.1);

float Y2 = 3.14159265359-Y;
float L2 = L * (8.0*exp(d*Y2)+A);

const vec3 moonlight2 = pow(normalize(moonlight),vec3(3.0))*length(moonlight);
const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.4))*length(moonlight);
vec3 gradN = mix(moonlight,moonlight2,1.-L2/2.0);
gradN = mix(gradN,moonlightRain,rainStrength);

return pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility *length(rawAvg) * (0.85+rainStrength*0.425)*grad3+ 0.2*pow(L2*1.2+1.2,invRain07)*moonVisibility*gradN;
}/*---------------------------------*/

#ifdef Reflections
const int maxf = 3;				//number of refinements
const float ref = 0.11;			//refinement multiplier
const float inc = 3.0;			//increasement factor at each step

vec3 nvec3(vec4 pos) {
    return pos.xyz/pos.w;
}
vec4 nvec4(vec3 pos) {
    return vec4(pos.xyz, 1.0);
}
float cdist(vec2 coord) {
	return max(abs(coord.s-0.5),abs(coord.t-0.5))*2.0;
}

vec4 raytrace(vec3 fragpos, vec3 skycolor, vec3 rvector) {
    vec4 color = vec4(0.0);
    vec3 start = fragpos;
	rvector *= 1.2;
    fragpos += rvector;
	vec3 tvector = rvector;
    int sr = 0;

    for(int i=0;i<25;i++){
        vec3 pos = nvec3(gbufferProjection * nvec4(fragpos)) * 0.5 + 0.5;
        if(pos.x < 0 || pos.x > 1 || pos.y < 0 || pos.y > 1 || pos.z < 0 || pos.z > 1.0) break;
        vec3 fragpos0 = vec3(pos.st, texture2D(depthtex1, pos.st).r);
        fragpos0 = nvec3(gbufferProjectionInverse * nvec4(fragpos0 * 2.0 - 1.0));
        float err = distance(fragpos,fragpos0);
		if(err < pow(length(rvector),1.175)){ //if(err < pow(length(rvector)*1.85,1.15)){ <- old, adjusted error check to reduce banding issues/glitches
                sr++;
                if(sr >= maxf){
					bool land = texture2D(depthtex1, pos.st).r < comp;
                    color = pow(texture2DLod(gaux1, pos.st, 1),vec4(2.2))*257.0;
					if (isEyeInWater == 0) color.rgb = land ? mix(color.rgb,skycolor*(0.7+0.3*tmult)*(1.33-rainStrength*0.8),calcFog(fragpos0.xyz)) : drawSun(rvector,skycolor,1.0);
					color.a = clamp(1.0 - pow(cdist(pos.st), 20.0), 0.0, 1.0);
					break;
                }
				tvector -= rvector;
                rvector *= ref;

}
        rvector *= inc;
        tvector += rvector;
		fragpos = start + tvector;
    }
    return color;
}
#endif

#if Clouds == 1
float subSurfaceScattering(vec3 vec,vec3 pos, float N) {
	return pow(max(dot(vec,normalize(pos)),0.0),N)*(N+1)/6.28;
}

float noisetexture(vec2 coord){
	return texture2D(noisetex, coord).x;
}

vec3 drawCloud(vec3 fposition, vec3 color) {
const float r = 3.2;
const vec4 noiseC = vec4(1.0,r,r*r,r*r*r);
const vec4 noiseWeights = 1.0/noiseC/dot(1.0/noiseC,vec4(1.0));

vec3 tpos = vec3(gbufferModelViewInverse * vec4(fposition, 0.0));
tpos = normalize(tpos);

float cosT = max(dot(fposition, upVec),0.0);

float wind = abs(frameTimeCounter/2000.0-0.5)+0.5;
float distortion = wind * 0.045;
	
float iMult = -log(cosT)*2.0+2.0;
float heightA = (400.0+300.0*sqrt(cosT))/(tpos.y);

for (int i = 1;i<22;i++) {
	vec3 intersection = tpos*(heightA-4.0*i*iMult); 			//curved cloud plane
	vec2 coord1 = intersection.xz/200000.0+wind*0.05;
	vec2 coord = fract(coord1/0.25);
	
	vec4 noiseSample = vec4(noisetexture(coord+distortion),
							noisetexture(coord*noiseC.y+distortion),
							noisetexture(coord*noiseC.z+distortion),
							noisetexture(coord*noiseC.w+distortion));

	float j = i / 22.0;
	coord = vec2(j+0.5,-j+0.5)/noiseTextureResolution + coord.xy + sin(coord.xy*3.14*j)/10.0 + wind*0.02*(j+0.5);
	
	vec2 secondcoord = 1.0 - coord.yx;
	vec4 noiseSample2 = vec4(noisetexture(secondcoord),
							 noisetexture(secondcoord*noiseC.y),
							 noisetexture(secondcoord*noiseC.z),
							 noisetexture(secondcoord*noiseC.w));

	float finalnoise = dot(noiseSample*noiseSample2,noiseWeights);
	float cl = max((sqrt(finalnoise*max(1.0-abs(i-11.0)/11*(0.15-1.7*rainStrength),0.0))-0.55)/(0.65+2.0*rainStrength)*clamp(cosT*cosT*2.0,0.0,1.0),0.0);

	float cMult = max(pow(30.0-i,3.5)/pow(30.,3.5),0.0)*6.0;

	float sunscattering = subSurfaceScattering(sunVec, fposition, 75.0)*pow(cl, 3.75);
	float moonscattering = subSurfaceScattering(-sunVec, fposition, 75.0)*pow(cl, 5.0);
	
	color = color*(1.0-cl)+cl*cMult*mix(cloudColor2,cloudColor,min(cMult,1.0)) * 0.05 + sunscattering+moonscattering;
	}
return color;
}/*---------------------------*/
#endif

#if Clouds == 2
float maxHeight = (cloud_height+200.0);

float bayer2(vec2 a){
	a = floor(a);
    return fract(dot(a,vec2(0.5,a.y*0.75)));
}
#define bayer4(a) (bayer2(0.5*(a))*0.25+bayer2(a))

float densityAtPos(in vec3 pos){
	pos /= 18.0;
	pos.xz *= 0.5;

	vec3 p = floor(pos);
	vec3 f = fract(pos);
	
	f = (f*f) * (3.0-2.0*f);
	f = sqrt(f);
	vec2 uv = p.xz + f.xz + p.y * 17.0;

	vec2 coord =  uv / 64.0;
	vec2 coord2 =  uv / 64.0 + 17.0 / 64.0;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.y);
}

float cloudPlane(in vec3 pos){
	float center = cloud_height*0.5+maxHeight*0.5;
	float difcenter = maxHeight-center;	
	float mult = (pos.y-center)/difcenter;
	
	vec3 samplePos = pos*vec3(0.5,0.5,0.5)*0.35+frameTimeCounter*vec3(0.5,0.,0.5);
	float noise = 0.0;
	float tot = 0.0;
	for(int i=0 ; i < 4; i++){
		noise += densityAtPos(samplePos*exp(i*1.05)*0.6+frameTimeCounter*i*vec3(0.5,0.,0.5)*0.6)*exp(-i*0.8);
		tot += exp(-i*0.8);
	}

return 1.0-pow(0.4,max(noise/tot-0.56-mult*mult*0.3+rainStrength*0.16,0.0)*2.2);
}

vec3 renderClouds(in vec3 pos, in vec3 color, const int cloudIT) {
	float dither = bayer4(gl_FragCoord.xy);

	//setup
	vec3 dV_view = pos.xyz;
	vec3 progress_view = vec3(0.0);
	pos = pos*2200.0 + cameraPosition; //makes max cloud distance not dependant of render distance	
	
	//3 ray setup cases : below cloud plane, in cloud plane and above cloud plane
	if (cameraPosition.y <= cloud_height){
		float maxHeight2 = min(maxHeight, pos.y);	//stop ray when intersecting before cloud plane end
		
		//setup ray to start at the start of the cloud plane and end at the end of the cloud plane
		dV_view *= -(maxHeight2-cloud_height)/dV_view.y/cloudIT;
		progress_view = dV_view*dither + cameraPosition + dV_view*(maxHeight2-cameraPosition.y)/(dV_view.y);
		if (pos.y < cloud_height) return color;	//don't trace if no intersection is possible
	}
	if (cameraPosition.y > cloud_height && cameraPosition.y < maxHeight){
		if (dV_view.y <= 0.0) {	
		float maxHeight2 = max(cloud_height, pos.y);	//stop ray when intersecting before cloud plane end
		
		//setup ray to start at eye position and end at the end of the cloud plane
		dV_view *= abs(maxHeight2-cameraPosition.y)/abs(dV_view.y)/cloudIT;
		progress_view = dV_view*dither + cameraPosition + dV_view*cloudIT;
		dV_view *= -1.0;
		}
else if (dV_view.y > 0.0) {		
		float maxHeight2 = min(maxHeight, pos.y);	//stop ray when intersecting before cloud plane end
		
		//setup ray to start at eye position and end at the end of the cloud plane
		dV_view *= -abs(maxHeight2-cameraPosition.y)/abs(dV_view.y)/cloudIT;
		progress_view = dV_view*dither + cameraPosition - dV_view*cloudIT;
		}
	}
	if (cameraPosition.y >= maxHeight){			
		float maxHeight2 = max(cloud_height, pos.y);	//stop ray when intersecting before cloud plane end

		//setup ray to start at eye position and end at the end of the cloud plane
		dV_view *= -abs(maxHeight2-maxHeight)/abs(dV_view.y)/cloudIT;
		progress_view = dV_view*dither + cameraPosition + dV_view*(maxHeight2-cameraPosition.y)/dV_view.y;
		if (pos.y > maxHeight) return color;	//don't trace if no intersection is possible
	}

	float mult = length(dV_view)/256.0;

	for (int i=0;i<cloudIT;i++) {
		float cloud = cloudPlane(progress_view)*40.0;
		float lightsourceVis = pow(clamp(progress_view.y-cloud_height,0.,200.)/200.,2.3);
		color = mix(color,mix(cloudColor2*0.05, cloudColor*0.15, lightsourceVis),1.0-exp(-cloud*mult));

		progress_view += dV_view;
	}

	return color;	
}
#endif

#ifdef customStars
float calcStars(vec3 pos){
 	vec3 p = pos * 256.0;
	vec3 flr = floor(p);
	float fr = length((p - flr) - 0.5);
	flr = fract(flr * 443.8975);
    flr += dot(flr, flr.xyz + 19.19);

 	float intensity = step(fract((flr.x + flr.y) * flr.z), 0.0025) * (1.0 - rainStrength);
	float stars = clamp((fr - 0.5) / (0.0 - 0.5), 0.0, 1.0);	//recreate smoothstep for opengl 120
    	  stars = stars * stars * (3.0 - 2.0 * stars);			//^

 	return stars * intensity;
}
#endif

#ifdef Refraction
mat2 rmatrix(float rad){
	return mat2(vec2(cos(rad), -sin(rad)), vec2(sin(rad), cos(rad)));
}

float calcWaves(vec2 coord){
	vec2 movement = abs(vec2(0.0, -frameTimeCounter * 0.31365));

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

vec2 calcBump(vec2 coord){
	const vec2 deltaPos = vec2(0.25, 0.0);

	float h0 = calcWaves(coord);
	float h1 = calcWaves(coord + deltaPos.xy);
	float h2 = calcWaves(coord - deltaPos.xy);
	float h3 = calcWaves(coord + deltaPos.yx);
	float h4 = calcWaves(coord - deltaPos.yx);

	float xDelta = ((h1-h0)+(h0-h2));
	float yDelta = ((h3-h0)+(h0-h4));

	return vec2(xDelta,yDelta)*0.05;
}
#endif

#ifdef RainReflections
uniform float wetness;
const float wetnessHalflife = 200.0f;
const float drynessHalflife = 75.0f;

float noisetexture(vec2 coord, float offset, float speed){
	   speed *= (0.001+rainStrength); //generate static noise after raining stopped for an improved wetness effect
	   offset *= rainNoise;
return texture2D(noisetex, fract(coord*offset + frameTimeCounter*speed)).x/offset;
}

float calcRainripples(vec2 pos){
	float wave = noisetexture(pos, 1.75, 0.1125);
		  wave -= noisetexture(pos, 1.8, -0.1125);

	return wave;
}
#endif

vec3 decode (vec2 enc){
    vec2 fenc = enc*4-2;
    float f = dot(fenc,fenc);
    float g = sqrt(1-f/4.0);
    vec3 n;
    n.xy = fenc*g;
    n.z = 1-f/2;
    return n;
}

void main() {

vec3 c = pow(texture2D(gaux1,texcoord).xyz,vec3(2.2))*257.;
vec3 hr = texture2D(composite,(floor(texcoord*vec2(viewWidth,viewHeight)/2.0)*2.0+1.0)/vec2(viewWidth,viewHeight)/2.0).rgb*30.0;

//Depth and fragpos
float depth0 = texture2D(depthtex0, texcoord).x;
vec4 fragpos0 = gbufferProjectionInverse * (vec4(texcoord, depth0, 1.0) * 2.0 - 1.0);
fragpos0 /= fragpos0.w;
vec3 normalfragpos0 = normalize(fragpos0.xyz);

float depth1 = texture2D(depthtex1, texcoord).x;
vec4 fragpos1 = gbufferProjectionInverse * (vec4(texcoord, depth1, 1.0) * 2.0 - 1.0);
	 fragpos1 /= fragpos1.w;
vec3 normalfragpos1 = normalize(fragpos1.xyz);
/*--------------------------------------------------------------------------------------------*/
vec4 trp = texture2D(gaux3,texcoord.xy);
bool transparency = dot(trp.xyz,trp.xyz) > 0.000001;
bool getlight = (eyeBrightness.y / 255.0) > 0.1;

#ifdef Refraction
if (transparency && texture2D(gnormal, texcoord).z < 0.2499 && isEyeInWater == 0) {
	vec2 wpos = (gbufferModelViewInverse*fragpos0).xz+cameraPosition.xz;
		 wpos *= 1.5;	//add a small offset from original waves for refractions and caustics

	vec2 refraction = texcoord.xy + calcBump(wpos);			
	c = pow(texture2D(gaux1, refraction).xyz, vec3(2.2))*257.0;	

	float caustics = calcWaves(wpos);
	if(getlight)c *= 1.0+ (3.0*caustics * (1.0 - rainStrength));
}
#endif

if (depth1 > comp){
vec3 cpos = normalize(gbufferModelViewInverse*fragpos1).xyz;
c = hr.rgb;
#ifdef customStars
	c += calcStars(cpos)*moonVisibility;
#endif
#if Clouds == 1
	c = drawCloud(normalfragpos1.xyz, c);
#endif
	c = drawSun(fragpos1.xyz, c, 1.0);
#ifdef Moonshading	
	c = drawMoon(fragpos1.xyz, c, 1.0);
#endif
#if Clouds == 2
float cheight = (cloud_height-32.0);
if (dot(fragpos1.xyz, upVec) > 0.0 || cameraPosition.y > cheight)c = renderClouds(cpos, c, cloudsIT);
#endif
}/*--------------------------------------*/

	//Draw fog
	vec3 fogC = hr.rgb*(0.7+0.3*tmult)*(1.33-rainStrength*0.67);
	float fogF = calcFog(fragpos0.xyz);
	/*----------------------------------------------------------------*/

if (transparency) {
	vec3 normal = texture2D(gnormal,texcoord).xyz;
	float sky = normal.z;

	bool iswater = sky < 0.2499;
	bool isice = sky > 0.2499 && sky < 0.4999;

	if (iswater) sky *= 4.0;
	if (isice) sky = (sky - 0.25)*4.0;

	if (!iswater && !isice) sky = (sky - 0.5)*4.0;

	sky = clamp(sky*1.2-2./16.0*1.2,0.,1.0);
	sky *= sky;

	normal = decode(normal.xy);

	bool reflective = dot(normal.xyz,normal.xyz) > 0.0;

	normal = normalize(normal);
	
		//draw fog for transparency
		float iswater2 = float(iswater);
		if(!getlight)c = mix(c,fogC,fogF-fogF)/ (1.0 + 1.0*iswater2);
		else c = mix(c,fogC,fogF-fogF)/ (1.0 + 5.0*night*iswater2);

		//Draw transparency
		vec3 finalAc = texture2D(gaux2, texcoord.xy).rgb;
		float alphaT = clamp(length(trp.rgb)*1.02,0.0,1.0);

		c = mix(c,c*(trp.rgb*0.9999+0.0001)*1.732,alphaT)*(1.0-alphaT) + finalAc;
		/*-----------------------------------------------------------------------------------------*/
	
#if defined MC_OS_MAC && defined MC_GL_VENDOR_ATI
	reflective = depth0 < depth1; //for some reason the reflective flag is broken on amd cards running macOS, this is a temporary workaround, making all translucent things reflective.
#endif		

	//Reflections
	if (reflective) {
		vec3 reflectedVector = reflect(normalfragpos1, normal);
		vec3 hV= normalize(reflectedVector - normalfragpos1);

		float normalDotEye = dot(hV, normalfragpos1);

		float F0 = 0.09;

		float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 4.0) ;
		fresnel = fresnel+F0*(1.0-fresnel);
	
		vec3 sky_c = getSkyc(reflectedVector*620.)*1.7;
#ifdef Reflections
#if Clouds == 1 || Clouds == 2
	#ifdef Cloud_reflection
		vec3 cloudVector = normalize(gbufferModelViewInverse*vec4(reflect(fragpos1.xyz, normal), 1.0)).xyz;
		#if Clouds == 1
			sky_c += drawCloud(reflectedVector, vec3(0.0))*1.5;
		#endif
		#if Clouds == 2 
			sky_c += renderClouds(cloudVector, c, cloudreflIT); 
		#endif
	#endif
#endif
		vec4 reflection = raytrace(fragpos0.xyz, sky_c, reflectedVector);
#else
		vec4 reflection = vec4(0.0);
		fresnel *= 0.5;
#endif
		sky_c = (isEyeInWater == 0)? ((drawSun(reflectedVector, sky_c, 1.0)+drawMoon(reflectedVector, sky_c, 1.0)) * 0.5)*sky : pow(vec3(0.25,0.5,0.72),vec3(2.2))*rawAvg*0.1;
		reflection.rgb = mix(sky_c, reflection.rgb, reflection.a)*0.5;

	#ifdef IceGlassReflections
		fresnel *= 0.5*float(isice) + 0.5*iswater2;
	#else
		fresnel *= 1.0*iswater2;
	#endif
		c = mix(c,reflection.rgb,fresnel);
	}
  }
	bool land = depth0 < comp;

#ifdef Reflections
	#ifdef RainReflections
	vec3 wnormal = texture2D(gdepth,texcoord).xyz;
		 wnormal = decode(wnormal.xy);

	float sky_lightmap = max(texture2D(gdepth,texcoord).w-2.0/16.0,0.0)*1.14285714286;
	float iswet = wetness*pow(sky_lightmap, 5.0)*sqrt(max(dot(wnormal,upVec),0.0));

#ifdef BiomeCheck
	bool isRaining = (BiomeTemp >= 0.15) && (BiomeTemp <= 1.0) && iswet > 0.01 && land && !transparency && isEyeInWater == 0.0;
#else
	bool isRaining = iswet > 0.01 && land && !transparency && isEyeInWater == 0.0;
#endif

	if (isRaining) {
		vec2 wpos = (gbufferModelViewInverse*fragpos0).xz+cameraPosition.xz;

		wnormal *= 1.0+calcRainripples(wpos); //modify normals with noise / rain ripples before reflecting
		vec3 reflectedVector = reflect(fragpos0.xyz, wnormal); //TODO Improve reflections distortion

		float normalDotEye = dot(normalize(reflectedVector - fragpos0.xyz), normalfragpos0.xyz);
		float fresnel = pow(clamp(1.0 + normalDotEye,0.0,1.0), 4.0);
		fresnel = fresnel+0.09*(1.0-fresnel);
	
		vec3 sky_c = getSkyc(reflectedVector);
		vec4 reflection = raytrace(fragpos0.xyz, sky_c, normalize(reflectedVector));
			 reflection.rgb = mix(sky_c, reflection.rgb, reflection.a)*0.5;
	
		c = mix(c.rgb, reflection.rgb, fresnel*iswet); //smooth out wetness start and end
		//c.rgb = wnormal;
	}
	#endif
#endif

	//Draw land and underwater fog
	vec3 foglandC = fogC;
		 foglandC.b *= (1.5-0.5*rainStrength);
	if(land)c = mix(c,foglandC*(1.0-isEyeInWater),fogF);
#if Clouds == 2
	if(!land && rainStrength > 0.01)c = mix(c,fogC,fogF*0.75);	//tint vl clouds with fog while raining
#endif
	#ifdef Underwater_Fog
	vec3 ufogC = fogC*0.25;
		 ufogC.g *= 1.0+2.0*inSwamp; //make fog greenish in swamp biomes

	if (isEyeInWater == 1.0) c = mix(c, ufogC, 1.0-exp(-length(fragpos0.xyz)/uFogDensity));
	#endif
	
	if (isEyeInWater == 2.0) c = mix(c, vec3(1.0, 0.0125, 0.0), 1.0-exp(-length(fragpos0.xyz))); //lava fog
	if(blindness > 0.9) c = mix(c, vec3(0.0), 1.0-exp(-length(fragpos1.xyz)*1.125));	//blindness fog


//Draw rain
float depth2 = texture2D(depthtex2, texcoord).x;
bool hand = (depth0 < depth1) || !(depth0 < depth2);
vec4 rain = texture2D(gaux4, texcoord);
if (rain.r > 0.0001 && rainStrength > 0.01 && hand){
	float rainRGB = 0.25;
	float rainA = rain.r;

	float torch_lightmap = 6.4 - min(rain.g/rain.r * 6.16,5.6);
	torch_lightmap = 0.1 / torch_lightmap / torch_lightmap - 0.002595;

	vec3 rainC = rainRGB*(pow(max(dot(normalfragpos0, sunVec)*0.1+0.9,0.0),6.0)*(0.1+tr*0.9)*pow(sunlight,vec3(0.25))*sunVisibility+pow(max(dot(normalfragpos0, -sunVec)*0.05+0.95,0.0),6.0)*48.0*moonlight*moonVisibility)*0.04 + 0.05*rainRGB*length(avgAmbient2);
	rainC += torch_lightmap*vec3(emissive_R,emissive_G,emissive_B);
	c = c*(1.0-rainA*0.3)+rainC*1.5*rainA;
}

#ifndef Volumetric_Lighting
#ifdef Godrays
	float sunpos = abs(dot(normalfragpos0,normalize(sunPosition.xyz)));
	float illuminationDecay = pow(sunpos,30.0)+pow(sunpos,16.0)*0.8+pow(sunpos,2.0)*0.125;
	
	vec2 deltaTextCoord = (lightPos-texcoord)*0.01;
	vec2 textCoord = texcoord*0.5+0.5;

	float gr = texture2DLod(gaux1, textCoord + deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 2.0 * deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 3.0 * deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 4.0 * deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 5.0 * deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 6.0 * deltaTextCoord,1).a;
		  gr += texture2DLod(gaux1, textCoord + 7.0 * deltaTextCoord,1).a;

	vec3 grC = lightColor*Godrays_Density;
	if(blindness < 1.0)c += grC*gr/7.0*illuminationDecay*(1.0-isEyeInWater);
#endif
#endif

#ifdef Volumetric_Lighting
const float exposure = 1.05;

//sun-moon switch
vec3 lightVec = -sunVec;
vec3 lightcol = moonlight*5.0;
if (sunVisibility > 0.2){
	lightVec = sunVec;
	lightcol = sunlight;
}

float phase = 2.5+exp(dot(normalfragpos0,lightVec)*3.0)/3.0;
float vgr = texture2DLod(gaux1, texcoord, 1).a;

vec3 vgrC = lightcol*exposure*phase*0.08*(0.25+0.75*tmult*tmult)*tr*(1.0+pow(1.0-eyeBrightnessSmooth.y/255.0,2.0))*(1.0-rainStrength*0.9);
if (depth0 > comp)vgrC = mix(vgrC, c, 0.5);
c += vgrC*vgr*(1.0-isEyeInWater)*(float(land)*0.2+0.8);
#endif

#ifdef Lens_Flares
c += texture2D(composite,texcoord.xy*0.5+0.5+1.0/vec2(viewWidth,viewHeight)).rgb*fading*30*30/100*pow(dot(texture2D(gaux1, vec2(1.0)/vec2(viewWidth,viewHeight)).w, 1.0), 2.0);
#endif

	c = (c/50.0*pow(eyeAdapt,0.88));
	gl_FragData[0] = vec4(c,1.0);
}
