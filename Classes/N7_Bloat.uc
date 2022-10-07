class N7_Bloat extends KFChar.ZombieBloat_STANDARD;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.bloat_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.bloat_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.bloat_diffuse');
}

defaultProperties
{
    MenuName="N7 Bloat"
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmBloat'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegBloat'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadBloat'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.bloat_cmb'
}
