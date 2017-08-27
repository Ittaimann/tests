// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#if !defined (MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED

	#include "UnityPBSLighting.cginc"
	#include "AutoLight.cginc"


			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal: NORMAL;
				float4 tangent: TANGENT;

			};

			struct v2f
			{
				float4 uv : TEXCOORD0;
				float3 normal: TEXCOORD1;
				float4 pos : SV_POSITION;

				#if defined(BINORMAL_PER_FRAGMENT)
					float4 tangent : TEXCOORD2;
				#else
					float3 tangent : TEXCOORD2;
					float3 binormal : TEXCOORD3;
				#endif

				float3 worldPos:TEXCOORD4;

				SHADOW_COORDS(5)

				#if defined(VERTEXLIGHT_ON)
					float3 vertexLightColor : TEXCOORD6;
				#endif
			};

			void ComputeVertexLightColor(appdata a,inout v2f i){
				#if defined (VERTEXLIGHT_ON)
					i.vertexLightColor = Shade4PointLights(
					unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
					unity_LightColor[0].rgb, unity_LightColor[1].rgb,
					unity_LightColor[2].rgb, unity_LightColor[3].rgb,
					unity_4LightAtten0, i.worldPos, i.normal
				);
				#endif
			}

			sampler2D _MainTex,_DetailTex;

			float4 _MainTex_ST,_DetailTex_ST;
			float4 _Tint;
			float _Smoothness;
			sampler2D _MetallicMap;
			float _Metallic;
			sampler2D _NormalMap,_DetailNormalMap;
			float _BumpScale,_DetailBumpScale;

			sampler2D _EmissionMap;
			float3 _Emission;

			sampler2D _OcclusionMap;
			float _OcclusionStrength;

			sampler2D _DetailMask;



			float GetMetallic (v2f i)
			{
				#if defined(_METALLIC_MAP)
					return tex2D(_MetallicMap,i.uv.xy).r*_Metallic;
				#else
					return _Metallic;
				#endif
			}

			float GetSmoothness (v2f i)
			{
				float smoothness=1;
				#if defined(_SMOOTHNESS_ALBEDO)
					smoothness=tex2D(_MainTex,i.uv.xy).a;
				#elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
					smoothness=tex2D(_MetallicMap,i.uv.xy).a;
				#endif

				return smoothness *_Smoothness;
			}

			float3 GetEmission(v2f i){
				#if defined(FORWARD_BASE_PASS)
					#if defined(_EMISSION_MAP)
						return tex2D(_EmissionMap, i.uv.xy)*_Emission;
					#else
						return _Emission;
					#endif
				#else
					return 0;
				#endif

			}

			float GetOcclusion(v2f i)
			{
				#if defined(_OCCLUSION_MAP)
					return lerp(1,tex2D(_OcclusionMap,i.uv.xy).g, _OcclusionStrength);
				#else
					return 1;
				#endif
			}

			float GetDetailMask(v2f i)
			{
				#if defined (_DETAIL_MASK)
					return tex2D(_DetailMask,i.uv.xy).a;
				#else
					return 1;
				#endif

			}

			float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
				return cross(normal, tangent.xyz) *
					(binormalSign * unity_WorldTransformParams.w);
			}

			float GetAlpha (v2f i){
				float alpha =_Tint.a;
				#if !defined(_SMOOTHNESS_ALBEDO)
					alpha*=tex2D(_MainTex,i.uv.xy).a;
				#endif
				return alpha;
			}


			v2f vert (appdata v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldPos=mul(unity_ObjectToWorld,v.vertex);
				o.normal=mul(unity_ObjectToWorld,float4 (v.normal,0));

				#if defined(BINORMAL_PER_FRAGMENT)
					o.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				#else
					o.tangent = UnityObjectToWorldDir(v.tangent.xyz);
					o.binormal = CreateBinormal(o.normal, o.tangent, v.tangent.w);
				#endif

				o.uv.xy= TRANSFORM_TEX(v.uv, _MainTex);
				o.uv.zw= TRANSFORM_TEX(v.uv, _DetailTex);

				TRANSFER_SHADOW(o);

				ComputeVertexLightColor(v,o);
				return o;
			}


			UnityLight CreateLight (v2f i){

				UnityLight light;
				#if defined(POINT) || defined(SPOT)
					light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
				#else
					light.dir = _WorldSpaceLightPos0.xyz;
				#endif


				UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);

			//	float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
				//attenuation*=GetOcclusion(i);
			//	UNITY_LIGHT_ATTENUATION(attenuation,0,i.worldPos);
				light.color = _LightColor0.rgb * attenuation;
				light.ndotl = DotClamped(i.normal, light.dir);
				return light;
			}

			float3 BoxProjection(float3 direction, float3 position, float4 cubemapPosition, float3 boxMin, float3 boxMax)
			{
				#if UNITY_SPECCUBE_BOX_PROJECTION
				UNITY_BRANCH
				if(cubemapPosition.w>0){
					float3 factors= (( direction>0 ? boxMax:boxMin)-position)/direction;
					float scalar=min(min(factors.x,factors.y),factors.z);

					direction= direction*scalar+(position-cubemapPosition);
				}
				#endif
				return direction;
			}

			UnityIndirect CreateIndirectLight (v2f i, float3 viewDir) {
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				#if defined(VERTEXLIGHT_ON)
					indirectLight.diffuse = i.vertexLightColor;
				#endif

				#if defined(FORWARD_BASE_PASS)

					indirectLight.diffuse+=max(0,ShadeSH9(float4(i.normal,1)));

					float3 reflectionDir=reflect(-viewDir,i.normal);

					Unity_GlossyEnvironmentData envData;
					envData.roughness=1-GetSmoothness(i);

					envData.reflUVW=BoxProjection(reflectionDir,i.worldPos,
							unity_SpecCube0_ProbePosition,unity_SpecCube0_BoxMin,
							unity_SpecCube0_BoxMax);

					float3 probe0=Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE(unity_SpecCube0),
													unity_SpecCube0_HDR,envData);

				  envData.reflUVW=BoxProjection(reflectionDir,i.worldPos,
							unity_SpecCube1_ProbePosition,unity_SpecCube1_BoxMin,
							unity_SpecCube1_BoxMax);

						#if UNITY_SPECCUBE_BLENDING
							float interpolator= unity_SpecCube0_BoxMin.w;
							UNITY_BRANCH
							if(interpolator<0.99999){
									float3 probe1 =Unity_GlossyEnvironment(UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0),
																	unity_SpecCube0_HDR,envData);
									indirectLight.specular=lerp(probe1,probe0,interpolator);
							}
							else{
									indirectLight.specular=probe0;
							}
						#else
							indirectLight.specular=probe0;
						#endif


						float occlusion =GetOcclusion(i);
						indirectLight.diffuse *= occlusion;
						indirectLight.specular *= occlusion;
				#endif

				return indirectLight;
			}

			float3 GetTangetSpaceNormal(v2f i){
				float3 normal=float3(0,0,1);
				#if defined(_NORMAL_MAP)
					normal=UnpackScaleNormal(tex2D(_NormalMap,i.uv.xy),_BumpScale);
				#endif
				#if defined(_DETAIL_NORMAL_MAP)
					float3 detailNormal=UnpackScaleNormal(tex2D(_DetailNormalMap,i.uv.zw),_DetailBumpScale);
					detailNormal=lerp(float3(0,0,1),detailNormal,GetDetailMask(i));
					normal=BlendNormals(normal,detailNormal);
					#endif
				return normal;
			}

			void InitializeFragmentNormal(inout v2f i)
			{


				float3 tangentSpaceNormal=GetTangetSpaceNormal(i);
				#if defined(BINORMAL_PER_FRAGMENT)
						float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
					#else
						float3 binormal = i.binormal;
					#endif
				i.normal=normalize(tangentSpaceNormal.x*i.tangent+
					tangentSpaceNormal.y*binormal+
					tangentSpaceNormal.z*i.normal);


			}

			float3 GetAlbedo(v2f i)
			{
				float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
				#if defined (_DETAIL_ALBEDO_MAP)
					float3 details =tex2D(_DetailTex,i.uv.zw)*unity_ColorSpaceDouble;
					albedo=lerp(albedo,albedo*details,GetDetailMask(i));
				#endif
				return albedo;
			}


			float4 frag (v2f i) : SV_Target
			{
				InitializeFragmentNormal(i);
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);


				float3 specularTint;
				float oneMinusReflectivity;
				float3 albedo = DiffuseAndSpecularFromMetallic(
					GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity
				);




				float4 color = UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, GetSmoothness(i),
					i.normal, viewDir,
					CreateLight(i),CreateIndirectLight(i,viewDir)
				);

				color.rgb+=GetEmission(i);
				return color;
			}
#endif
