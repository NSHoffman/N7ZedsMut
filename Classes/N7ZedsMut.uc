class N7ZedsMut extends Engine.Mutator
    config(N7ZedsMut);

/*************************
 ASSET IMPORTS
 *************************/

#exec OBJ LOAD FILE=KF_Specimens_Trip_N7.utx
#exec OBJ LOAD FILE=KF_Specimens_Trip_N7_Two.utx
#exec OBJ LOAD FILE=kf_gore_n7_sm.usx

/*************************
 BOOLEAN SETTINGS
 *************************/

const B_USE_ORIGINAL_ZED_SKINS_KEY = "bUseOriginalZedSkins";
const B_REPLACE_CLOT_KEY = "bReplaceClot";
const B_REPLACE_CRAWLER_KEY = "bReplaceCrawler";
const B_REPLACE_GOREFAST_KEY = "bReplaceGorefast";
const B_REPLACE_STALKER_KEY = "bReplaceStalker";
const B_REPLACE_SCRAKE_KEY = "bReplaceScrake";
const B_REPLACE_FLESHPOUND_KEY = "bReplaceFleshpound";
const B_REPLACE_BLOAT_KEY = "bReplaceBloat";
const B_REPLACE_SIREN_KEY = "bReplaceSiren";
const B_REPLACE_HUSK_KEY = "bReplaceHusk";
const B_REPLACE_BOSS_KEY = "bReplaceBoss";

var config bool
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

/*************************
 MUTATOR PROPERTIES
 *************************/

var const class<KFMonstersCollection> InitialMonstersCollectionClass;
var class<KFMonstersCollection> N7MonstersCollectionClass;
var class<KFMonstersCollection> FinalMonstersCollectionClass;

var class<N7ZedsConfigMutateAPI> MutateApiClass;

/*************************
 INITIALIZATION
 *************************/

simulated event PostBeginPlay()
{
    local KFGameType KFGT;

    KFGT = KFGameType(Level.Game);

    if (KFGT == None)
    {
        Destroy();
        return;
    }

    if (bEnableAutoReplacement && KFGT.MonsterCollection == class'KFMod.KFGameType'.default.MonsterCollection)
    {
        SetupMonsterCollection(KFGT);
    }

    SaveConfiguration();
}

function SaveConfiguration()
{
    self.SaveConfig();

    MutateApiClass.static.StaticSaveConfig();

    class'N7_Clot'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Clot');

    class'N7_Bloat'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Bloat');

    class'N7_Gorefast'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Gorefast');

    class'N7_Crawler'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Crawler');

    class'N7_Stalker'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Stalker');

    class'N7_PseudoStalker'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_PseudoStalker');
    class'N7_PseudoStalker'.static.StaticClearConfig("MinPseudos");
    class'N7_PseudoStalker'.static.StaticClearConfig("MaxPseudos");

    class'N7_Husk'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Husk');

    class'N7_Siren'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Siren');

    class'N7_Scrake'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Scrake');

    class'N7_Fleshpound'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Fleshpound');

    class'N7_Boss'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_Boss');

    class'N7_PseudoBoss'.static.StaticSaveConfig();
    ClearDefaultConfiguration(class'N7_PseudoBoss');
    class'N7_PseudoBoss'.static.StaticClearConfig("CombatStages");
    class'N7_PseudoBoss'.static.StaticClearConfig("PatHealth");
    class'N7_PseudoBoss'.static.StaticClearConfig("CGDamage");
}

function ClearDefaultConfiguration(class<KFMonster> MC)
{
    MC.static.StaticClearConfig("bPlayOwnFootsteps");
    MC.static.StaticClearConfig("SelectedEquipment");
    MC.static.StaticClearConfig("bPlayerShadows");
    MC.static.StaticClearConfig("bBlobShadow");
    MC.static.StaticClearConfig("PlacedCharacterName");
    MC.static.StaticClearConfig("PlacedFemaleCharacterName");
    MC.static.StaticClearConfig("bNoCoronas");
}

/*************************
 ZEDS REPLACEMENT LOGIC
 *************************/

function SetupMonsterCollection(KFGameType KFGT, optional bool bGameInit)
{
    ResolveMonstersCollection();

    AdjustMonsterClasses(KFGT);

    AdjustShortMonsterSquads();
    AdjustNormalMonsterSquads();
    AdjustLongMonsterSquads();
    AdjustFinalMonsterSquads();

    AdjustEndGameBoss(KFGT);

    ApplyMonstersCollection(KFGT, bGameInit);
}

function ResolveMonstersCollection()
{
    if (bUseOriginalZedSkins)
        N7MonstersCollectionClass = class'N7_MonstersCollection';
    else
        N7MonstersCollectionClass = default.N7MonstersCollectionClass;
}

function AdjustMonsterClasses(KFGameType KFGT)
{
    local int i;

    KFGT.MonsterClasses.Length = N7MonstersCollectionClass.default.MonsterClasses.Length;
    for (i = 0; i < N7MonstersCollectionClass.default.MonsterClasses.Length; i++)
    {
        if (ShouldReplaceZED(N7MonstersCollectionClass.default.MonsterClasses[i].MClassName))
        {
            FinalMonstersCollectionClass.default.MonsterClasses[i] = N7MonstersCollectionClass.default.MonsterClasses[i];
            FinalMonstersCollectionClass.default.StandardMonsterClasses[i] = N7MonstersCollectionClass.default.StandardMonsterClasses[i];

            KFGT.MonsterClasses[i].MClassName = N7MonstersCollectionClass.default.MonsterClasses[i].MClassName;
            KFGT.MonsterClasses[i].Mid = N7MonstersCollectionClass.default.MonsterClasses[i].Mid;
        }
        else
        {
            FinalMonstersCollectionClass.default.MonsterClasses[i] = InitialMonstersCollectionClass.default.MonsterClasses[i];
            FinalMonstersCollectionClass.default.StandardMonsterClasses[i] = InitialMonstersCollectionClass.default.StandardMonsterClasses[i];

            KFGT.MonsterClasses[i].MClassName = InitialMonstersCollectionClass.default.MonsterClasses[i].MClassName;
            KFGT.MonsterClasses[i].Mid = InitialMonstersCollectionClass.default.MonsterClasses[i].Mid;
        }
    }
}

function AdjustShortMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollectionClass.default.ShortSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollectionClass.default.ShortSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollectionClass.default.ShortSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollectionClass.default.ShortSpecialSquads[i].ZedClass[j];

            if (ShouldReplaceZED(N7ZedClass))
                FinalMonstersCollectionClass.default.ShortSpecialSquads[i].ZedClass[j] = N7ZedClass;
            else
                FinalMonstersCollectionClass.default.ShortSpecialSquads[i].ZedClass[j] = InitialZedClass;
        }
    }
}

function AdjustNormalMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollectionClass.default.NormalSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollectionClass.default.NormalSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollectionClass.default.NormalSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollectionClass.default.NormalSpecialSquads[i].ZedClass[j];

            if (ShouldReplaceZED(N7ZedClass))
                FinalMonstersCollectionClass.default.NormalSpecialSquads[i].ZedClass[j] = N7ZedClass;
            else
                FinalMonstersCollectionClass.default.NormalSpecialSquads[i].ZedClass[j] = InitialZedClass;
        }
    }
}

function AdjustLongMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollectionClass.default.LongSpecialSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollectionClass.default.LongSpecialSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollectionClass.default.LongSpecialSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollectionClass.default.LongSpecialSquads[i].ZedClass[j];

            if (ShouldReplaceZED(N7ZedClass))
                FinalMonstersCollectionClass.default.LongSpecialSquads[i].ZedClass[j] = N7ZedClass;
            else
                FinalMonstersCollectionClass.default.LongSpecialSquads[i].ZedClass[j] = InitialZedClass;
        }
    }
}

function AdjustFinalMonsterSquads()
{
    local int i, j;
    local string N7ZedClass, InitialZedClass;

    for (i = 0; i < N7MonstersCollectionClass.default.FinalSquads.Length; i++)
    {
        for (j = 0; j < N7MonstersCollectionClass.default.FinalSquads[i].ZedClass.Length; j++)
        {
            N7ZedClass = N7MonstersCollectionClass.default.FinalSquads[i].ZedClass[j];
            InitialZedClass = InitialMonstersCollectionClass.default.FinalSquads[i].ZedClass[j];

            if (ShouldReplaceZED(N7ZedClass))
                FinalMonstersCollectionClass.default.FinalSquads[i].ZedClass[j] = N7ZedClass;
            else
                FinalMonstersCollectionClass.default.FinalSquads[i].ZedClass[j] = InitialZedClass;
        }
    }
}

function AdjustEndGameBoss(KFGameType KFGT)
{
    if (bReplaceBoss)
    {
        FinalMonstersCollectionClass.default.EndGameBossClass = N7MonstersCollectionClass.default.EndGameBossClass;
        KFGT.EndGameBossClass = N7MonstersCollectionClass.default.EndGameBossClass;
    }
    else
    {
        FinalMonstersCollectionClass.default.EndGameBossClass = InitialMonstersCollectionClass.default.EndGameBossClass;
        KFGT.EndGameBossClass = InitialMonstersCollectionClass.default.EndGameBossClass;
    }
}

function ApplyMonstersCollection(KFGameType KFGT, bool bGameInit)
{
    KFGT.SpecialEventMonsterCollections[0] = FinalMonstersCollectionClass;
    KFGT.MonsterCollection = FinalMonstersCollectionClass;

    if (!bGameInit)
    {
        KFGT.PrepareSpecialSquads();
        KFGT.LoadUpMonsterList();
    }
}

/*************************
 SETTINGS MANAGEMENT
 *************************/

function bool ShouldReplaceZED(string ZedClass)
{
    switch (ZedClass)
    {
        case N7MonstersCollectionClass.default.MonsterClasses[0].MClassName  : return bReplaceClot;
        case N7MonstersCollectionClass.default.MonsterClasses[1].MClassName  : return bReplaceCrawler;
        case N7MonstersCollectionClass.default.MonsterClasses[2].MClassName  : return bReplaceGorefast;
        case N7MonstersCollectionClass.default.MonsterClasses[3].MClassName  : return bReplaceStalker;
        case N7MonstersCollectionClass.default.MonsterClasses[4].MClassName  : return bReplaceScrake;
        case N7MonstersCollectionClass.default.MonsterClasses[5].MClassName  : return bReplaceFleshpound;
        case N7MonstersCollectionClass.default.MonsterClasses[6].MClassName  : return bReplaceBloat;
        case N7MonstersCollectionClass.default.MonsterClasses[7].MClassName  : return bReplaceSiren;
        case N7MonstersCollectionClass.default.MonsterClasses[8].MClassName  : return bReplaceHusk;
        case N7MonstersCollectionClass.default.EndGameBossClass              : return bReplaceBoss;

        default: return False;
    }
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
    local string GeneralSettings, ZedsSettings;

    GeneralSettings = "General Settings";
    ZedsSettings = "Zeds Settings";

    super.FillPlayInfo(PlayInfo);

    PlayInfo.AddSetting(GeneralSettings, B_USE_ORIGINAL_ZED_SKINS_KEY, "Use Original ZEDs Skins", 0, 0, "Check");

    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_CLOT_KEY, "Replace Clots", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_CRAWLER_KEY, "Replace Crawlers", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_GOREFAST_KEY, "Replace Gorefasts", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_STALKER_KEY, "Replace Stalkers", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_SCRAKE_KEY, "Replace Scrakes", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_FLESHPOUND_KEY, "Replace Fleshpounds", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_BLOAT_KEY, "Replace Bloats", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_SIREN_KEY, "Replace Sirens", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_HUSK_KEY, "Replace Husks", 0, 0, "Check",,,, True);
    PlayInfo.AddSetting(ZedsSettings, B_REPLACE_BOSS_KEY, "Replace Boss", 0, 0, "Check",,,, True);
}

static event string GetDescriptionText(string Property)
{
    switch (Property)
    {
        case B_USE_ORIGINAL_ZED_SKINS_KEY   : return "Use original ZEDs skins";
        case B_REPLACE_CLOT_KEY             : return "Replace original Clots";
        case B_REPLACE_CRAWLER_KEY          : return "Replace original Crawlers";
        case B_REPLACE_GOREFAST_KEY         : return "Replace original Gorefasts";
        case B_REPLACE_STALKER_KEY          : return "Replace original Stalkers";
        case B_REPLACE_SCRAKE_KEY           : return "Replace original Scrakes";
        case B_REPLACE_FLESHPOUND_KEY       : return "Replace originalFleshpounds";
        case B_REPLACE_BLOAT_KEY            : return "Replace original Bloats";
        case B_REPLACE_SIREN_KEY            : return "Replace original Sirens";
        case B_REPLACE_HUSK_KEY             : return "Replace original Husks";
        case B_REPLACE_BOSS_KEY             : return "Replace original Boss";

        default : return super.GetDescriptionText(Property);
    }
}

/*************************
 MUTATE API
 *************************/

function Mutate(string MutateString, PlayerController Sender)
{
    local KFGameType KFGT;
    local N7ZedsConfigMutateAPI mutateCommand;
    local array<string> mutateArgs;
    local byte bShouldUpdateZeds;

    KFGT = KFGameType(Level.Game);
    Split(MutateString, " ", mutateArgs);

    if (KFGT != None)
    {
        mutateCommand = new(self) MutateApiClass;

        mutateCommand.Init(Sender, mutateArgs);
        mutateCommand.Run(bShouldUpdateZeds);

        if (bool(bShouldUpdateZeds))
        {
            SetupMonsterCollection(KFGT);
        }
    }

    super.Mutate(MutateString, Sender);
}

defaultProperties
{
    FriendlyName="N7 Zeds"
    Description="Mutator modifies vanilla ZEDs providing them with new appearance and behaviour features + fixes a bunch of well-known issues and exploits which could negatively affect the original gameplay."
    GroupName="KFN7ZedsMut"

    InitialMonstersCollectionClass=class'KFMod.KFMonstersCollection'
    N7MonstersCollectionClass=class'N7_MonstersCollection_SAVAGE'
    FinalMonstersCollectionClass=class'N7_MonstersCollection_FINAL'

    MutateApiClass=class'N7ZedsConfigMutateAPI'

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
