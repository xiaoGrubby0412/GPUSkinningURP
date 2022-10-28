Shader "XingWo/Object_PBR_Simplelify"
{
	Properties
	{
		_MainColor("Main Color", Color) = (1,1,1,0)
		_MainTeture("Main Teture", 2D) = "white" {}
		_RoughnessMap("RoughnessMap", 2D) = "white" {}
		_Metallic("Metallic", Range( 0 , 1)) = 0.2
		_Gloss("Gloss", Range( 0 , 1)) = 0.3
		_NormalIntensity("NormalIntensity", Range( 0.001 , 2)) = 1
		_NormalMap("Normal Map", 2D) = "bump" {}
		[HDR]_Emission("Emission", Color) = (0,0,0,0)
	}

	SubShader
	{
		LOD 100
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		Cull Off
		AlphaToMask Off

		Pass
		{
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual

			HLSLPROGRAM

			#pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
			#pragma multi_compile _ _SHADOWS_SOFT
			#pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
			
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
			#pragma multi_compile _ SHADOWS_SHADOWMASK

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
			#pragma multi_compile _ LIGHTMAP_ON

			#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#include "Packages/com.unity.shadergraph/ShaderGraphLibrary/Functions.hlsl"
			
			#include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"
			
			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 texcoord2 : TEXCOORD2;
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				float4 lightmapUVOrVertexSH : TEXCOORD0;
				half4 fogFactorAndVertexLight : TEXCOORD1;
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				float4 shadowCoord : TEXCOORD2;
				#endif
				float4 tSpace0 : TEXCOORD3;
				float4 tSpace1 : TEXCOORD4;
				float4 tSpace2 : TEXCOORD5;
				#if defined(ASE_NEEDS_FRAG_SCREEN_POSITION)
				float4 screenPos : TEXCOORD6;
				#endif
				float4 ase_texcoord7 : TEXCOORD7;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NormalMap_ST;
			float4 _MainColor;
			float4 _MainTeture_ST;
			float4 _Emission;
			float4 _RoughnessMap_ST;
			float _NormalIntensity;
			float _Metallic;
			float _Gloss;
			CBUFFER_END

			sampler2D _NormalMap;
			sampler2D _MainTeture;
			sampler2D _RoughnessMap;

			VertexOutput vert( VertexInput v  )
			{
				float4 normal = float4(v.ase_normal, 0);
				float4 tangent = float4(v.ase_tangent.xyz, 0);

				float4 pos = skin4(v.vertex, v.texcoord1, v.texcoord2);
				normal = skin4(normal, v.texcoord1, v.texcoord2);
				tangent = skin4(tangent, v.texcoord1, v.texcoord2);

				v.vertex = pos;
				v.ase_normal = normal.xyz;
				v.ase_tangent = float4(tangent.xyz, v.ase_tangent.w);
				
				VertexOutput o = (VertexOutput)0;

				o.ase_texcoord7.xy = v.texcoord.xy;//UV
				o.ase_texcoord7.zw = 0;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 positionVS = TransformWorldToView( positionWS );
				float4 positionCS = TransformWorldToHClip( positionWS );

				VertexNormalInputs normalInput = GetVertexNormalInputs(v.ase_normal, v.ase_tangent);

				o.tSpace0 = float4(normalInput.normalWS, positionWS.x);
				o.tSpace1 = float4(normalInput.tangentWS, positionWS.y);
				o.tSpace2 = float4(normalInput.bitangentWS, positionWS.z);

				half3 vertexLight = VertexLighting( positionWS, normalInput.normalWS );
				
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				
				o.clipPos = positionCS;

				return o;
			}

			half4 frag ( VertexOutput IN ) : SV_Target
			{
				float3 WorldNormal = normalize(IN.tSpace0.xyz);
				float3 WorldTangent = IN.tSpace1.xyz;
				float3 WorldBiTangent = IN.tSpace2.xyz;

				float3 WorldPosition = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				float3 WorldViewDirection = _WorldSpaceCameraPos.xyz  - WorldPosition;
				float4 ShadowCoords = float4(0, 0, 0, 0);

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
					ShadowCoords = IN.shadowCoord;
				#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
				#endif
	
				WorldViewDirection = SafeNormalize( WorldViewDirection );

				float2 uv_NormalMap = IN.ase_texcoord7.xy * _NormalMap_ST.xy + _NormalMap_ST.zw;
				float3 tex2DNode13 = UnpackNormalScale( tex2D( _NormalMap, uv_NormalMap ), 1.0f );
				float2 appendResult30 = (float2(tex2DNode13.r , tex2DNode13.g));
				float dotResult36 = dot( appendResult30 , appendResult30 );
				float3 appendResult40 = (float3(( _NormalIntensity * appendResult30 ) , sqrt( ( 1.0 - saturate( dotResult36 ) ) )));
				float3 NormalMap47 = appendResult40;
				float3 normalizeResult147 = normalize( BlendNormal( WorldNormal , NormalMap47 ) );
				float3 normalizeResult145 = normalize( _MainLightPosition.xyz );
				float dotResult146 = dot( normalizeResult147 , normalizeResult145 );
				float halfLambert95 = ( ( dotResult146 * 0.5 ) + 0.5 );
				float2 uv_MainTeture = IN.ase_texcoord7.xy * _MainTeture_ST.xy + _MainTeture_ST.zw;
				float4 MainColor50 = ( _MainColor * tex2D( _MainTeture, uv_MainTeture ) );
				
				float2 uv_RoughnessMap = IN.ase_texcoord7.xy * _RoughnessMap_ST.xy + _RoughnessMap_ST.zw;
				
				float3 Albedo = MainColor50.rgb;
				float3 Normal = NormalMap47;
				float3 Emission = _Emission.rgb;
				float3 Specular = 0.5;
				float Metallic = _Metallic;
				float Smoothness = ( _Gloss * tex2D( _RoughnessMap, uv_RoughnessMap ).g );
				float Occlusion = 1;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;
				float3 BakedGI = 0;
				float3 RefractionColor = 1;
				float RefractionIndex = 1;
				float3 Transmission = 1;
				float3 Translucency = 1;

				InputData inputData;
				inputData.positionWS = WorldPosition;
				inputData.viewDirectionWS = WorldViewDirection;
				inputData.shadowCoord = ShadowCoords;

				inputData.normalWS = TransformTangentToWorld(Normal, half3x3( WorldTangent, WorldBiTangent, WorldNormal ));

				float3 SH = SampleSH(inputData.normalWS.xyz);

				inputData.bakedGI = SAMPLE_GI( IN.lightmapUVOrVertexSH.xy, SH, inputData.normalWS );
				
				inputData.normalizedScreenSpaceUV = GetNormalizedScreenSpaceUV(IN.clipPos);
				inputData.shadowMask = SAMPLE_SHADOWMASK(IN.lightmapUVOrVertexSH.xy);

				half4 color = UniversalFragmentPBR(
					inputData, 
					Albedo, 
					Metallic, 
					Specular, 
					Smoothness, 
					Occlusion, 
					Emission, 
					Alpha);

				return color;
			}
			ENDHLSL
		}

		Pass
		{
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM

			#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"
			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_tangent : TANGENT;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord : TEXCOORD0;
				float4 texcoord2 : TEXCOORD2;
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _NormalMap_ST;
			float4 _MainColor;
			float4 _MainTeture_ST;
			float4 _Emission;
			float4 _RoughnessMap_ST;
			float _NormalIntensity;
			float _Metallic;
			float _Gloss;
			CBUFFER_END
			
			float3 _LightDirection;

			VertexOutput vert( VertexInput v )
			{
				float4 normal = float4(v.ase_normal, 0);
				float4 tangent = float4(v.ase_tangent.xyz, 0);

				float4 pos = skin4(v.vertex, v.texcoord1, v.texcoord2);
				normal = skin4(normal, v.texcoord1, v.texcoord2);
				tangent = skin4(tangent, v.texcoord1, v.texcoord2);

				v.vertex = pos;
				v.ase_normal = normal.xyz;
				v.ase_tangent = float4(tangent.xyz, v.ase_tangent.w);
				
				VertexOutput o;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float3 normalWS = TransformObjectToWorldDir(v.ase_normal);

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				o.clipPos = clipPos;
				return o;
			}

			half4 frag(VertexOutput IN) : SV_TARGET
			{
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				return 0;
			}
			ENDHLSL
		}
	}
}
