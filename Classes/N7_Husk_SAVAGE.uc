class N7_Husk_SAVAGE extends N7_Husk;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7_Two.burns_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7_Two.burns_emissive_mask');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_energy_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_env_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_fire_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7_Two.burns_shdr');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7_Two.burns_cmb');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmHusk'
    DetachedLegClass=class'N7_SeveredLegHusk'
    DetachedHeadClass=class'N7_SeveredHeadHusk'
    Skins(0)=Texture'KF_Specimens_Trip_N7_Two.burns.burns_tatters'
    Skins(1)=Shader'KF_Specimens_Trip_N7_Two.burns.burns_shdr'
}
