Shader "ShaderDXT/DXT1CompressTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Rate ("Rate", Float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;
            float _Rate;

            #include "DXT1.cginc"

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed3 frag(v2f i) : SV_Target
            {
                if (i.uv.x > _Rate)
                {
                    uint2 pixelCoord = uint2(i.uv * _MainTex_TexelSize.zw);
        
                    float4 normalizedBlock = BlockToNormalized(EncodeDXT1(BlockCoord(i.uv))) + 0.5;
        
                    return DecodeDXT1(NormalizedToBlock(normalizedBlock - 0.5), SubpixelCoord(i.uv));
                }
                return tex2D(_MainTex, i.uv);
            }
            ENDCG
        }
    }
}
