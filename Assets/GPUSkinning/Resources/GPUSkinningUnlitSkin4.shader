Shader "GPUSkinning/GPUSkinning_Unlit_Skin4"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
	}

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Assets/GPUSkinning/Resources/GPUSkinningInclude.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
		half3 normal : NORMAL;
		float4 tangent : TANGENT;
		float2 uv : TEXCOORD0;
		float4 uv2 : TEXCOORD1;
		float4 uv3 : TEXCOORD2;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct v2f
	{
		float2 uv : TEXCOORD0;
		float4 vertex : SV_POSITION;
	};

	sampler2D _MainTex;
	float4 _MainTex_ST;
	fixed _Cutoff;

	v2f vert(appdata v)
	{
		UNITY_SETUP_INSTANCE_ID(v);

		v2f o;
		
		float4 pos = skin4(v.vertex, v.uv2, v.uv3);

		o.vertex = UnityObjectToClipPos(pos);
		o.uv = TRANSFORM_TEX(v.uv, _MainTex);
		return o;
	}

	fixed4 frag(v2f i) : SV_Target
	{
		fixed4 col = tex2D(_MainTex, i.uv);
		clip(col.a - _Cutoff);
		return col;
	}
	ENDCG

	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 200

		Pass
		{
			cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF
			ENDCG
		}
		
		Pass
		{
			Name "ShadowCaster"
			Tags {"LightMode" = "ShadowCaster"}
			
			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			#pragma multi_compile_shadowcaster
			#pragma multi_compile ROOTON_BLENDOFF ROOTON_BLENDON_CROSSFADEROOTON ROOTON_BLENDON_CROSSFADEROOTOFF ROOTOFF_BLENDOFF ROOTOFF_BLENDON_CROSSFADEROOTON ROOTOFF_BLENDON_CROSSFADEROOTOFF
			#include "UnityCG.cginc"

			struct v2f_shadow
			{
				V2F_SHADOW_CASTER;
			};

			v2f_shadow vert_shadow(appdata v)
			{
				v2f_shadow o;
				// Skinning
				{
					float4 normal = float4(v.normal, 0);
					//float4 tangent = float4(v.tangent.xyz, 0);
                
					float4 pos = skin4(v.vertex, v.uv2, v.uv3);
					normal = skin4(normal, v.uv2, v.uv3);
					//tangent = skin4(tangent, v.uv2, v.uv3);
                
					v.vertex = pos;
					v.normal = normal.xyz;
					//v.tangent = float4(tangent.xyz, v.tangent.w);
				}
				
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);
				return o;
			}

			float4 frag_shadow(v2f_shadow i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}
			
			ENDCG
		}
	}
	
//	Fallback "Diffuse"
}
