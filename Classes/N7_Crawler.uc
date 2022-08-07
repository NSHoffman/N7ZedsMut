class N7_Crawler extends KFChar.ZombieCrawler_STANDARD;

simulated function PostBeginPlay() 
{
    super.PostBeginPlay();

    PounceSpeed = 375 + Rand(125);
    MeleeRange = 75 + Rand(25);
}

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.crawler_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.crawler_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.crawler_diff');
}

defaultProperties
{
    MenuName="N7 Crawler"
    GroundSpeed=180.00000
    WaterSpeed=160.00000
    ControllerClass=Class'N7ZedsMut.N7_CrawlerController'
    DetachedArmClass=Class'N7ZedsMut.N7_SeveredArmCrawler'
    DetachedLegClass=Class'N7ZedsMut.N7_SeveredLegCrawler'
    DetachedHeadClass=Class'N7ZedsMut.N7_SeveredHeadCrawler'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.crawler_cmb'
}
