#version 120
/* DRAWBUFFERS:7 */

#define composite2
#include "shaders.settings"

#ifdef Bloom
varying vec2 texcoord;
uniform sampler2D composite;
uniform float viewWidth;
uniform float viewHeight;
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
const bool compositeMipmapEnabled = true;
#endif

void main() {

#ifdef Bloom
	const int nSteps = 25;
	const int center = 12;		//=nSteps-1 / 2

	vec3 blur = vec3(0.0);
	float tw = 0.0;
	for (int i = 0; i < nSteps; i++) {
		float dist = abs(i-float(center))/center;
		float weight = (exp(-(dist*dist)/ 0.28));

		vec3 bsample = texture2D(composite,(texcoord.xy*4.0 + 2.0*vec2(pw,ph)*vec2(i-center,0.0))).rgb;

		blur += bsample*weight;
		tw += weight;
	}
	blur /= tw;
	blur = clamp(blur,0.0,1.0); //fix flashing black square
	gl_FragData[0] = vec4(blur, 1.0); 
#else
	gl_FragData[0] = vec4(0.0);
#endif
}

