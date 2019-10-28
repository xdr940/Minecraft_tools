#version 120
#extension GL_ARB_shader_texture_lod : enable //This extension must always be enabled to prevent issues with amd linux drivers
/* DRAWBUFFERS:01 */
//Specular buffer 012
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
/*--------------------
//ADJUSTABLE VARIABLES//
---------------------*/

#define nMap 0				//[0 1 2]0=Off 1=Bumpmapping, 2=Parallax, also adjust in vertex
#define POM_RES 32			//Texture / Resourcepack resolution. [32 64 128 256 512]
#define POM_DIST 16.0		//[8.0 16.0 24.0 32.0 40.0 48.0 56.0 64.0]
#define POM_DEPTH 0.30		//[0.10 0.20 0.30 0.40 0.50 0.60 0.70 0.80 0.90 1.0]

/*---------------------------
//END OF ADJUSTABLE VARIABLES//
----------------------------*/

/* Don't remove me
const int gcolorFormat = RGBA8;
const int gdepthFormat = RGBA8;
const int gnormalFormat = RGB10_A2;
const int compositeFormat = R11F_G11F_B10F;
const int gaux1Format = RGBA16;
const int gaux2Format = R11F_G11F_B10F;
const int gaux3Format = R11F_G11F_B10F;		
const int gaux4Format = R11F_G11F_B10F;	
-----------------------------------------*/

varying vec4 color;
varying vec4 texcoord;
varying vec4 normal;

uniform sampler2D texture;
//uniform sampler2D specular;

//encode normal in two channel (xy),torch and material(z) and sky lightmap (w)
vec4 encode (vec3 n){
    float p = sqrt(n.z*8+8);
    return vec4(n.xy/p + 0.5,texcoord.z,texcoord.w);
}

vec3 RGB2YCoCg(vec3 c){
		return vec3( 0.25*c.r+0.5*c.g+0.25*c.b, 0.5*c.r-0.5*c.b +0.5, -0.25*c.r+0.5*c.g-0.25*c.b +0.5);
}
vec3 newnormal = normal.xyz;
#if nMap >= 1
uniform sampler2D normals;
varying float dist;
varying vec3 viewVector;
varying mat3 tbnMatrix;
varying vec4 vtexcoordam; // .st for add, .pq for mul
varying vec2 vtexcoord;

mat2 mipmap = mat2(dFdx(vtexcoord.xy*vtexcoordam.pq), dFdy(vtexcoord.xy*vtexcoordam.pq));	
vec4 readNormal(in vec2 coord){
	return texture2DGradARB(normals,fract(coord)*vtexcoordam.pq+vtexcoordam.st,mipmap[0],mipmap[1]);
}

vec4 calcPOM(vec4 albedo){
	vec2 newCoord = vtexcoord.xy*vtexcoordam.pq+vtexcoordam.st;
#if nMap == 2
	if (dist < POM_DIST && viewVector.z < 0.0 && readNormal(vtexcoord.xy).a < 1.0){
		const float res_stepths = 0.33 * POM_RES;
		vec2 pstepth = viewVector.xy * POM_DEPTH / (-viewVector.z * POM_RES);
		vec2 coord = vtexcoord.xy;
		for (int i= 0; i < res_stepths && (readNormal(coord.xy).a < 1.0-float(i)/POM_RES); ++i) coord += pstepth;
	
		newCoord = fract(coord.xy)*vtexcoordam.pq+vtexcoordam.st;
	}
#endif
	//vec4 specularity = texture2DGradARB(specular, newCoord, dcdx, dcdy);
	vec3 bumpMapping = texture2DGradARB(normals, newCoord, mipmap[0],mipmap[1]).rgb*2.0-1.0;
	newnormal = normalize(bumpMapping * tbnMatrix);

return albedo = texture2DGradARB(texture, newCoord, mipmap[0],mipmap[1])*color;
}
#endif

void main() {

vec4 albedo = texture2D(texture,texcoord.xy)*color;
#if nMap >= 1
	 albedo = calcPOM(albedo);
#endif
vec4 cAlbedo = vec4(RGB2YCoCg(albedo.rgb),albedo.a);

bool pattern = (mod(gl_FragCoord.x,2.0)==mod(gl_FragCoord.y,2.0));
cAlbedo.g = (pattern)?cAlbedo.b: cAlbedo.g;
cAlbedo.b = normal.a;

	gl_FragData[0] = cAlbedo;
	gl_FragData[1] = encode(newnormal.xyz);
	//gl_FragData[2] = specularity;
}