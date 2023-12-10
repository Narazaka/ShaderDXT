Shader "ShaderDXT/DXT1DecompressRAWCustomRenderTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Name "Update"

            CGPROGRAM
            #pragma fragment frag

            #include "UnityCustomRenderTexture.cginc"
            #pragma vertex CustomRenderTextureVertexShader

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            #define DECODESCALE uint2(4, 4)
            #include "DXT1.cginc"

            fixed3 frag(v2f_customrendertexture i) : SV_Target
            {
                return DecodeDXT1(NormalizedToBlock(UVColor(i.localTexcoord.xy)), i.localTexcoord.xy);
            }
            ENDCG
        }
    }
}
