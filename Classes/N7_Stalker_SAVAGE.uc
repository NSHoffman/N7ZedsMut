class N7_Stalker_SAVAGE extends N7_Stalker;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.stalker_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_diff');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.stalker_spec');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_invisible');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.StalkerCloakOpacity_cmb');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.StalkerCloakEnv_rot');
    myLevel.AddPrecacheMaterial(Material'KF_Specimens_Trip_N7.stalker_opacity_osc');
    myLevel.AddPrecacheMaterial(Material'KFCharacters.StalkerSkin');
}

defaultProperties
{
    DetachedArmClass=class'N7_SeveredArmStalker'
    DetachedLegClass=class'N7_SeveredLegStalker'
    DetachedHeadClass=class'N7_SeveredHeadStalker'
    Skins(0)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
    Skins(1)=Shader'KF_Specimens_Trip_N7.stalker_invisible'
    Skins(2)=FinalBlend'KF_Specimens_Trip_N7.stalker_fb'
    Skins(3)=Combiner'KF_Specimens_Trip_N7.stalker_cmb'
}
