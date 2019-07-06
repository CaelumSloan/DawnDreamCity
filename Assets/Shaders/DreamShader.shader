// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DreamShader"
{
    Properties
    {
        _TintColor ("TintColor", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase"}

        ZWrite On
        Blend One Zero

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

			#pragma multi_compile _ SHADOWS_SCREEN

            #include "UnityCG.cginc"
			#include "UnityStandardBRDF.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
				float3 normal : TEXCOORD1;
#if defined(SHADOWS_SCREEN)
				float4 shadowCoordinates : TEXCOORD5;
#endif
            };

            float4 _TintColor;

            v2f vert (appdata v)
            {
                v2f o;

#if defined(SHADOWS_SCREEN)
				o.shadowCoordinates = o.position;
#endif

				float attenuation = tex2D(_ShadowMapTexture, i.shadowCoordinates.xy);

                o.vertex = UnityObjectToClipPos(v.vertex);
				o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float3 lightColor = _LightColor0.rgb;
				return (DotClamped(lightDir, i.normal) * float4(lightColor, 1) + float4(ShadeSH9(half4(i.normal, 1)), 1)) * _TintColor;
            }
            ENDCG
        }


		Pass 
		{
			Tags 
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "UnityCG.cginc"

			struct VertexData 
			{
				float4 position : POSITION;
				float3 normal : NORMAL;
			};

			float4 MyShadowVertexProgram(VertexData v) : SV_POSITION
			{
				float4 position = UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
				return UnityApplyLinearShadowBias(position);
			}

			half4 MyShadowFragmentProgram() : SV_TARGET 
			{
				return 0;
			}

			ENDCG
		}
    }
}
