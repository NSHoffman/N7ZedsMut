class N7_Scrake_SAVAGE extends N7_Scrake;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.scrake_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.scrake_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.scrake_spec');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.scrake_saw_panner');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.scrake_FB');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.Chainsaw_blade_diff');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmScrake'
    DetachedLegClass=class'N7_SeveredLegScrake'
    DetachedHeadClass=class'N7_SeveredHeadScrake'
    Skins(0)=Shader'KF_Specimens_Trip_N7.scrake_FB'
    Skins(1)=TexPanner'KF_Specimens_Trip_N7.scrake_saw_panner'
}
