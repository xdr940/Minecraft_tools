#version 120

varying vec4 texcoord;
uniform sampler2D gcolor;

void main() {

	vec3 color = texture2D(gcolor, texcoord.st).rgb;

	color = clamp(color,0.0,1.0);
	gl_FragData[0] = vec4(color, 1.0);
	
}
