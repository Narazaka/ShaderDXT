Shader "ShaderDXT/DXT1DecompressCustomRenderTexture"
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
            // make fog work
            #pragma multi_compile_fog

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
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _MainTex_TexelSize;

            #include "DXT1.cginc"

            fixed3 frag(v2f_customrendertexture i) : SV_Target
            {
                float4 color = tex2Dlod(_MainTex, float4(i.localTexcoord.xy, 0, 0));
                return DecodeDXT1(NormalizedToBlock(color), SubpixelCoord(uint2(i.localTexcoord.xy * _MainTex_TexelSize.zw * 4)));
            }
            ENDCG
        }
    }
}
