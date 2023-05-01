class N7_Siren_SAVAGE extends N7_Siren;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.siren_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.siren_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.siren_diffuse');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.siren_hair');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.siren_hair_fb');
}

defaultProperties
{
    DetachedLegClass=class'N7_SeveredLegSiren'
    DetachedHeadClass=class'N7_SeveredHeadSiren'
    Skins(0)=FinalBlend'KF_Specimens_Trip_N7.siren_hair_fb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.siren_cmb'
}
