Shader "ShaderDXT/DXT1CompressRAWCustomRenderTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
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

            #include "DXT1.cginc"

            float4 frag(v2f_customrendertexture i) : SV_Target
            {
                return BlockToNormalized(EncodeDXT1(i.localTexcoord.xy));
            }
            ENDCG
        }
    }
}
