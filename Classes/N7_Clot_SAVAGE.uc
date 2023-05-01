class N7_Clot_SAVAGE extends N7_Clot;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.clot_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.clot_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.clot_diffuse');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.clot_spec');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmClot'
    DetachedLegClass=class'N7_SeveredLegClot'
    DetachedHeadClass=class'N7_SeveredHeadClot'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.clot_cmb'
}
