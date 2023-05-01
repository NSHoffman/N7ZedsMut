class N7_Gorefast_SAVAGE extends N7_Gorefast;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.gorefast_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.gorefast_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.gorefast_diff');
}

defaultProperties
{
    ControllerClass=class'N7_GorefastController'
    DetachedArmClass=class'N7_SeveredArmGorefast'
    DetachedLegClass=class'N7_SeveredLegGorefast'
    DetachedHeadClass=class'N7_SeveredHeadGorefast'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.gorefast_cmb'
}
