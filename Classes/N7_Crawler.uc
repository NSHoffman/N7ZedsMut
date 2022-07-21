class N7_Crawler extends KFChar.ZombieCrawler_STANDARD;

simulated function PostBeginPlay() 
{
    super.PostBeginPlay();

    PounceSpeed = 375 + Rand(125);
    MeleeRange = 75 + Rand(25);
}

defaultProperties
{
    MenuName="N7 Crawler"
    GroundSpeed=180.00000
    WaterSpeed=160.00000
    ControllerClass=Class'N7ZedsMut.N7_CrawlerController'
}
