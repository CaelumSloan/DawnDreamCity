// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/DreamShader"
{
    Properties
    {
        _TintColor ("TintColor", Color) = (1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
		Tags 
		{
			"RenderType"="Opaque"
		}
        Pass
        {

			Tags 
			{ 
				"RenderType"="Opaque"
				"Queue" = "Geometry"
				"LightMode" = "ForwardBase"
			}
            
			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile _ SHADOWS_SCREEN

            #pragma vertex vert
            #pragma fragment frag

			#define FORWARD_BASE_PASS

			#include "UnityStandardBRDF.cginc"
			#include "AutoLight.cginc"

			sampler2D _MainTex;

            struct appdata
            {
                float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : TEXCOORD1;

				SHADOW_COORDS(5)
            };

            float4 _TintColor;

            v2f vert (appdata v)
            {
                v2f i;

                i.pos = UnityObjectToClipPos(v.vertex);
				i.normal = UnityObjectToWorldNormal(v.normal);
				i.uv = v.uv;

				TRANSFER_SHADOW(i);

                return i;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
				float3 lightDir = _WorldSpaceLightPos0.xyz;
				float4 lightColor = float4(_LightColor0.rgb, 1);

				float attenuation = 1;
				#if defined(SHADOWS_SCREEN)
				attenuation = SHADOW_ATTENUATION(i);
				#endif
				float4 directionalLightContribution = DotClamped(lightDir, i.normal);

				float4 dirLight = (directionalLightContribution * lightColor) * attenuation;
				float4 ambientLight = float4(ShadeSH9(half4(i.normal, 1)), 1);

				float4 texColor = tex2D(_MainTex, i.uv) ;

				float4 color = float4(lerp(_TintColor.rgb, texColor.rgb, texColor.a), 1);

				return (dirLight + ambientLight) * color;
            }
            ENDCG
        }

		Tags 
		{
			"LightMode" = "ForwardAdd"
		}
		Pass 
		{
			Tags
			{
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma vertex vert
			#pragma fragment frag

			#define POINT

			#include "UnityStandardBRDF.cginc"
			#include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
				float3 worldPos : TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f i;
				i.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return i;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				UNITY_LIGHT_ATTENUATION(attenuation, 0, i.worldPos);

				float4 color;
				color.a = _LightColor0.a * attenuation;

				return float4(_LightColor0.rgb * attenuation, 1);
            }
            ENDCG
		}

		Tags 
		{
			//"RenderType"="Opaque" 
			"Queue" = "Geometry" 
			"LightMode" = "ShadowCaster"
		}
		Pass 
		{
			Tags 
			{
				//"RenderType"="Opaque"
				"Queue" = "Geometry"
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "UnityCG.cginc"

			struct VertexData {
				float4 position : POSITION;
				float3 normal : NORMAL;
			};

			#if defined(SHADOWS_CUBE)
				struct Interpolators {
					float4 position : SV_POSITION;
					float3 lightVec : TEXCOORD0;
				};

				Interpolators MyShadowVertexProgram (VertexData v) {
					Interpolators i;
					i.position = UnityObjectToClipPos(v.position);
					i.lightVec =
						mul(unity_ObjectToWorld, v.position).xyz - _LightPositionRange.xyz;
					return i;
				}

				float4 MyShadowFragmentProgram (Interpolators i) : SV_TARGET {
					float depth = length(i.lightVec) + unity_LightShadowBias.x;
					depth *= _LightPositionRange.w;
					return UnityEncodeCubeShadowDepth(depth);
				}
			#else
				float4 MyShadowVertexProgram (VertexData v) : SV_POSITION {
					float4 position =
						UnityClipSpaceShadowCasterPos(v.position.xyz, v.normal);
					return UnityApplyLinearShadowBias(position);
				}

				half4 MyShadowFragmentProgram () : SV_TARGET {
					return 0;
				}
			#endif

			ENDCG
			}
		}
}
