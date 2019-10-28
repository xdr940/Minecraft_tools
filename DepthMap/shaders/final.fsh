#version 120

float BLUR_AMOUNT = 1.6; //I preffere something between 1.0 and 2.0
#define clipping far

//https://github.com/sp614x/optifine/blob/master/OptiFineDoc/doc/shaders.txt
uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;
uniform sampler2D  gdepthtex;
uniform sampler2D composite;
uniform sampler2D noisetex;
/*
depthtex0   everything
depthtex1   no translucent objects (water, stained glass)
depthtex2   no translucent objects (water, stained glass), no handheld objects
*/
uniform float near;// near viewing plane distance,全黑，等于0.05
uniform float far;// far viewing plane distance ,全白, 等于设置里的renders distances
uniform sampler2D normals;
varying vec4 texcoord;//varying 存储的是顶点着色器的输出，同时作为片段着色器的输入

vec4 getDepth(vec2 coord) {
  /*
  返回值在0.~1.之间
  */
  //float far = 512;
  vec4 temp = texture2D(depthtex0, coord);

  //return  2.0 * near * far / (far + near - (2.0 * temp - 1.0) * (far - near)) / clipping;
  return (1/(1-temp))/10000;//优化有用
//  return normalize(temp);
  //texture2D(depthtex0,coord) ->0.999非常接近，原因以及如何操作

  //return texture2D(depthtex0,coord)/far*2;
  //return texture2D(normals,coord);
  //return vec4(near,near,near,1);
  //return 0;//全黑
	//return 1;//全白
	//return 0.5;//全灰色

}
//texture2D
/*
The texture2D function returns a texel, i.e. the (color) value of the texture for the given coordinates.
 The function has one input parameter of the type sampler2D and one input parameter of the type vec2 : sampler,
  the uniform the texture is bound to, and coord, the 2-dimensional coordinates of the texel to look up.

There are texture lookup functions to access the image data.
Texture lookup functions can be called in the vertex and fragment shader.
 When looking up a texture in the vertex shader, level of detail is not yet computed, however there are some special lookup functions for that (function names end with "Lod").
The parameter "bias" is only available in the fragment shader It is an optional parameter you can use to add to the current level of detail.
Function names ending with "Proj" are the projective versions, the texture coordinate is divided by the last component of the texture coordinate vector.

*/


void main() {
	vec4 depth = getDepth(texcoord.st);

  //关于texcoord.st : 就是前两位分量， 由于这个四维向量代表的是纹理， 为了代码可解释性
  //就用.st索引， 用xy索引其实一样，就是为了更方便理解，如下
  /*
  if (depth.z>0.5){
    gl_FragColor = vec4(1, 0,0, 1.0);
  }else{
    gl_FragColor = vec4(0,1,0, 1.0);


  }
*/
  /*
  You may also wonder why "rgba" is used and not "xyzw".
  GLSL allows using the following names for vector component lookup:
x,y,z,w	Useful for points, vectors, normals
r,g,b,a	Useful for colors
s,t,p,q	Useful for texture coordinates

  */
	gl_FragColor = vec4(depth.xyz, 1.0);

}
