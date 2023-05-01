class N7_Fleshpound_SAVAGE extends N7_Fleshpound;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.fleshpound_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.fleshpound_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.fleshpound_diff');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmPound'
    DetachedLegClass=class'N7_SeveredLegPound'
    DetachedHeadClass=class'N7_SeveredHeadPound'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.fleshpound_cmb'
}
