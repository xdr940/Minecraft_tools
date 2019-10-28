#version 120
/* DRAWBUFFERS:4 */

//#define defskybox		//Render the default skybox, including stars. Only rendered during night time. Causes lighting issues while going from nighttime to daytime.

varying vec4 color;

const int FOGMODE_LINEAR = 9729;
const int FOGMODE_EXP = 2048;

uniform int fogMode;

void main() {
	
#ifdef defskybox
	gl_FragData[0] = color;
	float fogFactor = 1.0;
	if (fogMode == FOGMODE_EXP) {
		fogFactor = clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0);
	} else if (fogMode == FOGMODE_LINEAR) {
		fogFactor = 1.0 - clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0);
	}
	gl_FragData[0] = mix(gl_FragData[0],gl_Fog.color,1.0-fogFactor);
#else
	gl_FragData[0] = vec4(0.0); //remove default sky etc to prevent it from messing with out shader sky.
#endif

}