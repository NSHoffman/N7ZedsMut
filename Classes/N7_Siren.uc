class N7_Siren extends KFChar.ZombieSiren_STANDARD;

/* Shooting the siren can't interrupt her screaming */
simulated function bool HitCanInterruptAction()
{
    return !bShotAnim;
}

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
    MenuName="N7 Siren"
    ShakeEffectScalar=4.500000
    MinShakeEffectScale=3.250000
    ScreamRadius=1000
    ScreamDamageType=Class'N7ZedsMut.N7_SirenScreamDamage'
    Skins(0)=FinalBlend'KF_Specimens_Trip_N7.siren_hair_fb'
    Skins(1)=Combiner'KF_Specimens_Trip_N7.siren_cmb'
}
