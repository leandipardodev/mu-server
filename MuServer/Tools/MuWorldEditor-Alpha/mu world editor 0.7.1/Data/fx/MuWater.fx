#include "shared.fx"
#include "terrainShared.fx"

float4 PS(VS_TERRAIN_OUTPUT i) : COLOR0
{
	i.UV0.x+=g_fTime*0.1f;
	i.UV0.y+=sin(g_fTime*2+i.UV0.x*5)*0.02f;
	float4 color	= tex2D(g_samDiffuse, i.UV0);//*tex2D(g_samLight, i.UV1);
	return color*i.Color;
}

technique Render
{
    pass P0
    {
	    VertexShader = compile vs_1_1 TERRAIN_VS();
        PixelShader  = compile ps_2_0 PS();
    }
}