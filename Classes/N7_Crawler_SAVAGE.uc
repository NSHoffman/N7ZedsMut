class N7_Crawler_SAVAGE extends N7_Crawler;

static simulated function PreCacheMaterials(LevelInfo myLevel)
{
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.crawler_cmb');
    myLevel.AddPrecacheMaterial(Combiner'KF_Specimens_Trip_N7.crawler_env_cmb');
    myLevel.AddPrecacheMaterial(Texture'KF_Specimens_Trip_N7.crawler_diff');
}

defaultProperties
{
    ControllerClass=class'N7_CrawlerController'
    DetachedArmClass=class'N7_SeveredArmCrawler'
    DetachedLegClass=class'N7_SeveredLegCrawler'
    DetachedHeadClass=class'N7_SeveredHeadCrawler'
    Skins(0)=Combiner'KF_Specimens_Trip_N7.crawler_cmb'
}
