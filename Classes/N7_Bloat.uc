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
    GroundSpeed=90.000000
    WaterSpeed=105.000000
    Skins(0)=Combiner'KF_Specimens_Trip_N7.bloat_cmb'
}
