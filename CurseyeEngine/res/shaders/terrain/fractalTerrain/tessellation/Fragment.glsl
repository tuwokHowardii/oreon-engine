#version 430

in vec3 position;
flat in vec3 tangent;

struct DirectionalLight
{
	float intensity;
	vec3 ambient;
	vec3 direction;
	vec3 color;
};

struct Fractal
{
	sampler2D normalmap;
	int scaling;
};

uniform Fractal fractals[10];
uniform vec3 eyePosition;
uniform DirectionalLight sunlight;
uniform float scaleY;
uniform float scaleXZ;
uniform float sightRangeFactor;
uniform int largeDetailedRange;

const float zFar = 10000;
const vec3 fogColor = vec3(0.62,0.85,0.95);

float emission;
float shininess;

float diffuse(vec3 direction, vec3 normal, float intensity)
{
	return max(0.0, dot(normal, -direction) * intensity);
}

float specular(vec3 direction, vec3 normal, vec3 eyePosition, vec3 vertexPosition)
{
	vec3 reflectionVector = normalize(reflect(direction, normal));
	vec3 vertexToEye = normalize(eyePosition - vertexPosition);
	
	float specular = max(0, dot(vertexToEye, reflectionVector));
	
	return pow(specular, shininess) * emission;
}

void main()
{		
	float dist = length(eyePosition - position);
	float height = position.y;
	
	// normalmap/occlusionmap/splatmap coords
	vec2 mapCoords = (position.xz + scaleXZ/2)/scaleXZ;

	 vec3 normal = normalize(
							 (2*(texture(fractals[0].normalmap, mapCoords*fractals[0].scaling).rbg)-1)
							+(2*(texture(fractals[1].normalmap, mapCoords*fractals[1].scaling).rbg)-1)
							+(2*(texture(fractals[2].normalmap, mapCoords*fractals[2].scaling).rbg)-1)
							+(2*(texture(fractals[3].normalmap, mapCoords*fractals[3].scaling).rbg)-1)
							+(2*(texture(fractals[4].normalmap, mapCoords*fractals[4].scaling).rbg)-1)
							+(2*(texture(fractals[5].normalmap, mapCoords*fractals[5].scaling).rbg)-1)
							+(2*(texture(fractals[6].normalmap, mapCoords*fractals[6].scaling).rbg)-1)
							);
	
	if (dist < largeDetailedRange-20)
	{
		float attenuation = -dist/(largeDetailedRange-20) + 1;
		vec3 bitangent = normalize(cross(tangent, normal));
		mat3 TBN = mat3(tangent,normal,bitangent);
		
		vec3 bumpNormal =    (2*(texture(fractals[7].normalmap, mapCoords*fractals[7].scaling).rbg)-1)
							+(2*(texture(fractals[8].normalmap, mapCoords*fractals[8].scaling).rbg)-1)
							+(2*(texture(fractals[9].normalmap, mapCoords*fractals[9].scaling).rbg)-1);
		bumpNormal.xz *= attenuation;
		
		normal = normalize(TBN * normalize(bumpNormal));
	}
	
	vec3 diffuseLight = vec3(0.0);
	vec3 specularLight = vec3(0.0);
	float diffuseFactor = 0.0;
	float specularFactor = 0.0;
	
	emission = 0;
	shininess = 0;
	
	vec3 grass = vec3(0.123,0.163,0.04);
	vec3 rock = vec3(0.2,0.2,0.2);
	vec3 darkRock = vec3(0.02,0.02,0.02);
	vec3 sand = vec3(0.1,0.066,0.032);
	vec3 snow = vec3(1,1,1);
	
	float diffuse = diffuse(sunlight.direction, normal, sunlight.intensity);
	float specular = specular(sunlight.direction, normal, eyePosition, position);
	diffuseLight = sunlight.ambient + sunlight.color * diffuse;
	specularLight = sunlight.color * specular;
	
	vec3 fragColor;
	vec3 sandrock = mix(sand,rock, clamp(height/(scaleY/2)+0.2,0,1));
	vec3 sandrocksnow = mix(sandrock,snow, clamp((height-scaleY/4)/(scaleY/2),0,1));
	fragColor = mix(darkRock,sandrocksnow, clamp((height+scaleY/2)/(scaleY/4),0,1));
	float grassFactor = clamp(height/(scaleY*4)+0.95,0.9,1);
	if (normal.y > grassFactor){
		fragColor = mix(grass,fragColor,(1-normal.y)*10);
	}
	
	fragColor *= diffuseLight;
	fragColor += specularLight;
	
	float fogFactor = -0.0005/sightRangeFactor*(dist-zFar/5*sightRangeFactor);
	
    vec3 rgb = mix(fogColor, fragColor, clamp(fogFactor,0,1));
	
	gl_FragColor = vec4(rgb,1);
}