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
			float _Metallic;
			sampler2D _NormalMap,_DetailNormalMap;
			float _BumpScale,_DetailBumpScale;

			float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
				return cross(normal, tangent.xyz) *
					(binormalSign * unity_WorldTransformParams.w);
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

			//	UNITY_LIGHT_ATTENUATION(attenuation,0,i.worldPos);
				light.color = _LightColor0.rgb * attenuation;
				light.ndotl = DotClamped(i.normal, light.dir);
				return light;
			}

			UnityIndirect CreateIndirectLight (v2f i) {
				UnityIndirect indirectLight;
				indirectLight.diffuse = 0;
				indirectLight.specular = 0;

				#if defined(VERTEXLIGHT_ON)
					indirectLight.diffuse = i.vertexLightColor;
				#endif

				#if defined(FORWARD_BASE_PASS)
					indirectLight.diffuse+=max(0,ShadeSH9(float4(i.normal,1)));
				#endif

				return indirectLight;
			}


			void InitializeFragmentNormal(inout v2f i)
			{
			
				
				float3 mainNormal=UnpackScaleNormal(tex2D(_NormalMap,i.uv.xy),_BumpScale);
				float3 detailNormal=UnpackScaleNormal(tex2D(_DetailNormalMap,i.uv.zw),_DetailBumpScale);
			
				float3 tangentSpaceNormal=BlendNormals(mainNormal,detailNormal);
				#if defined(BINORMAL_PER_FRAGMENT)
						float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
					#else
						float3 binormal = i.binormal;
					#endif
				i.normal=normalize(tangentSpaceNormal.x*i.tangent+
					tangentSpaceNormal.y*binormal+
					tangentSpaceNormal.z*i.normal);


			}



			float4 frag (v2f i) : SV_Target
			{
				InitializeFragmentNormal(i);				
				float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

				float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
				albedo*=tex2D(_DetailTex,i.uv.zw)*unity_ColorSpaceDouble;
				float3 specularTint;
				float oneMinusReflectivity;
				albedo = DiffuseAndSpecularFromMetallic(
					albedo, _Metallic, specularTint, oneMinusReflectivity
				);
				
				
	
				
				return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,
					CreateLight(i),CreateIndirectLight(i)
				);
			}
#endif