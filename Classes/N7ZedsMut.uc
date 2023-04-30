class N7ZedsMut extends Engine.Mutator
    config(N7ZedsMut);

#exec OBJ LOAD FILE=KF_Specimens_Trip_N7.utx
#exec OBJ LOAD FILE=KF_Specimens_Trip_N7_Two.utx
#exec OBJ LOAD FILE=kf_gore_n7_sm.usx

var const class<KFMonstersCollection> InitialMonstersCollection;
var class<KFMonstersCollection> N7MonstersCollection;

var() config bool
    bEnableAutoReplacement,
    bUseOriginalZedSkins,
    bReplaceClot, 
    bReplaceCrawler,
    bReplaceGorefast,
    bReplaceStalker,
    bReplaceScrake,
    bReplaceFleshpound,
    bReplaceBloat,
    bReplaceSiren,
    bReplaceHusk,
    bReplaceBoss;

simulated event PostBeginPlay() {
    local KFGameType KFGT;

    KFGT = KFGameType(Level.Game);

    if (KFGT == None) 
    {
        Destroy();
        return;
    }

    if (bEnableAutoReplacement && KFGT.MonsterCollection == class'KFMod.KFGameType'.default.MonsterCollection)
    {
        if (bUseOriginalZedSkins)
            N7MonstersCollection = class'N7_MonstersCollection';

        SetupMonsterCollection(KFGT);
    }
}

static function FillPlayInfo(PlayInfo PlayInfo) 
{
    local string N7ZedsConfig;

    N7ZedsConfig = "N7 Zeds Mutator Config";
    super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(N7ZedsConfig, "bEnableAutoReplacement", "Enable ZEDs replacement", 0, 0, "Check");
    PlayInfo.AddSetting(N7ZedsConfig, "bUseOriginalZedSkins", "Use original ZED skins", 0, 0, "Check");

    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceClot", "Replace original Clots", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceCrawler", "Replace original Crawlers", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceGorefast", "Replace original Gorefasts", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceStalker", "Replace original Stalkers", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceScrake", "Replace original Scrakes", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceFleshpound", "Replace original Fleshpounds", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceBloat", "Replace original Bloats", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceSiren", "Replace original Sirens", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceHusk", "Replace original Husks", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(N7ZedsConfig, "bReplaceBoss", "Replace original Boss", 0, 0, "Check",,,, True);
}

static event string GetDescriptionText(string Property) 
{
    switch (Property) 
    {
        case "bEnableAutoReplacement"   : return "Enable ZEDs replacement";
        case "bUseOriginalZedSkins"     : return "Use original ZED skins";
        case "bReplaceClot"             : return "Replace original Clots";
        case "bReplaceCrawler"          : return "Replace original Crawlers";
        case "bReplaceGorefast"         : return "Replace original Gorefasts";
        case "bReplaceStalker"          : return "Replace original Stalkers";
        case "bReplaceScrake"           : return "Replace original Scrakes";
        case "bReplaceFleshpound"       : return "Replace original Fleshpounds";
        case "bReplaceBloat"            : return "Replace original Bloats";
        case "bReplaceSiren"            : return "Replace original Sirens";
        case "bReplaceHusk"             : return "Replace original Husks";
        case "bReplaceBoss"             : return "Replace original Boss";

        default                         : return super.GetDescriptionText(Property);
    }
}

function bool ShouldReplaceZED(string ZedClass)
{
    switch (ZedClass) 
    {
        case N7MonstersCollection.default.MonsterClasses[0].MClassName  : return bReplaceClot;
        case N7MonstersCollection.default.MonsterClasses[1].MClassName  : return bReplaceCrawler;
        case N7MonstersCollection.default.MonsterClasses[2].MClassName  : return bReplaceGorefast;
        case N7MonstersCollection.default.MonsterClasses[3].MClassName  : return bReplaceStalker;
        case N7MonstersCollection.default.MonsterClasses[4].MClassName  : return bReplaceScrake;
        case N7MonstersCollection.default.MonsterClasses[5].MClassName  : return bReplaceFleshpound;
        case N7MonstersCollection.default.MonsterClasses[6].MClassName  : return bReplaceBloat;
        case N7MonstersCollection.default.MonsterClasses[7].MClassName  : return bReplaceSiren;
        case N7MonstersCollection.default.MonsterClasses[8].MClassName  : return bReplaceHusk;
        case N7MonstersCollection.default.EndGameBossClass              : return bReplaceBoss;

        default: return False;
    }
}

function SetupMonsterCollection(out KFGameType KFGT)
{
    AdjustMonsterClasses();

    AdjustShortMonsterSquads();
    AdjustNormalMonsterSquads();
    AdjustLongMonsterSquads();
    AdjustFinalMonsterSquads();

    AdjustEndGameBoss();

    KFGT.SpecialEventMonsterCollections[0] = N7MonstersCollection;
    KFGT.MonsterCollection = N7MonstersCollection;
}

function AdjustMonsterClasses()
{
    local int i;

    for (i = 0; i < N7MonstersCollection.default.MonsterClasses.Length; i++)
    {
        if (!ShouldReplaceZED(N7MonstersCollection.default.MonsterClasses[i].MClassName))
        {
            N7MonstersCollection.default.MonsterClasses[i] = InitialMonstersCollection.default.MonsterClasses[i];
        }
    }
}

function AdjustShortMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollection.default.ShortSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollection.default.ShortSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollection.default.ShortSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollection.default.ShortSpecialSquads[i].ZedClass[j];

            if (!ShouldReplaceZED(N7ZedClass))
            {
                N7MonstersCollection.default.ShortSpecialSquads[i].ZedClass[j] = InitialZedClass;
            }
        }
    }
}

function AdjustNormalMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollection.default.NormalSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollection.default.NormalSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollection.default.NormalSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollection.default.NormalSpecialSquads[i].ZedClass[j];

            if (!ShouldReplaceZED(N7ZedClass))
            {
                N7MonstersCollection.default.NormalSpecialSquads[i].ZedClass[j] = InitialZedClass;
            }
        }
    }
}

function AdjustLongMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollection.default.LongSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollection.default.LongSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollection.default.LongSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollection.default.LongSpecialSquads[i].ZedClass[j];

            if (!ShouldReplaceZED(N7ZedClass))
            {
                N7MonstersCollection.default.LongSpecialSquads[i].ZedClass[j] = InitialZedClass;
            }
        }
    }
}

function AdjustFinalMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollection.default.FinalSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollection.default.FinalSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollection.default.FinalSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollection.default.FinalSquads[i].ZedClass[j];

            if (!ShouldReplaceZED(N7ZedClass))
            {
                N7MonstersCollection.default.FinalSquads[i].ZedClass[j] = InitialZedClass;
            }
        }
    }
}

function AdjustEndGameBoss()
{
    if (!bReplaceBoss)
    {
        N7MonstersCollection.default.EndGameBossClass = InitialMonstersCollection.default.EndGameBossClass;
    }
}

defaultProperties 
{
    FriendlyName="N7 Zeds"
    Description="Adds some changes to zeds behaviour making them more aggressive"
    GroupName="KFN7ZedsMut"

    InitialMonstersCollection=class'KFMod.KFMonstersCollection'
    N7MonstersCollection=class'N7_MonstersCollection_VIOLENT'
    
    bEnableAutoReplacement=True
    bUseOriginalZedSkins=False

    bReplaceClot=True
    bReplaceCrawler=True
    bReplaceGorefast=True
    bReplaceStalker=True
    bReplaceScrake=True
    bReplaceFleshpound=True
    bReplaceBloat=True
    bReplaceSiren=True
    bReplaceHusk=True
    bReplaceBoss=True
}
