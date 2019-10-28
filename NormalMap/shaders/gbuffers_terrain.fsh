#version 120
uniform sampler2D texture;
varying vec3 tintColor;
varying vec4 texcoord;
varying vec3 normal;
void main(){

vec4 blockColor = texture2D(texture,texcoord.st);
blockColor.rgb+=tintColor;
	gl_FragData[0] = vec4(normal,1.0);

}
