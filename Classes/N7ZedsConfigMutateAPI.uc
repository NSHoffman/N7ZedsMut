class N7ZedsConfigMutateAPI extends Core.Object 
    within N7ZedsMut 
    config(N7ZedsMut);

/*************************
 TYPINGS
 *************************/

struct ConfigSetting
{
    var const string Id, Key;
};

struct CommandInfo
{
    var const array<ConfigSetting> Settings;
    var const string Alias, Description, Signature, SettingsText;
    var const bool bAffectsZedConfig;
    var bool bAdminOnly;
};

/*************************
 CONSTANTS
 *************************/

const COMMANDS_COUNT = 14;

const INFO_Help = 0;
const INFO_Cfg = 1;

const TEMPLATE_KEY = "%KEY%";
const TEMPLATE_VALUE = "%VALUE%";

var protected const CommandInfo Commands[COMMANDS_COUNT];
var protected const config byte flagAdminOnlyCommand[COMMANDS_COUNT];
var protected const config string Prefix;

/*************************
 PROPERTIES
 *************************/

var public bool bStatus;

var protected PlayerController Sender;
var protected CommandInfo Command;

var protected string Alias;
var protected config string MsgSuccessTemplate, MsgAccessDenied;
var protected array<string> Args;

/*************************
 MAIN FLOW
 *************************/

public function Init(PlayerController PC, array<string> MutateArgs)
{
    local int i;

    Sender = PC;

    if (MutateArgs.Length > 0)
    {
        Alias = Locs(MutateArgs[0]);
     
        for (i = 1; i < MutateArgs.Length; i++)
        {
            Args[i - 1] = MutateArgs[i];
        }

        FindCommand();
    }
    else bStatus = False;
}

public function bool Run(optional out byte bShouldUpdateZeds)
{
    local string value;

    if (!bStatus) return bStatus;

    CheckPermissions();

    if (!bStatus) return bStatus;

    if (Command.bAffectsZedConfig)
    {
        ProcessSettingsChangingCommand(value);

        if (!bStatus) return bStatus;

        bShouldUpdateZeds = 1;
        Msg(GetSuccessMessage(Command.SettingsText, value));
    }
    else
    {
        ProcessInfoCommand();
    }

    return bStatus;
}

protected function FindCommand()
{
    local int i;

    for (i = 0; i < COMMANDS_COUNT; i++)
    {
        if (Alias ~= GetFullAlias(Commands[i].Alias))
        {
            Command = Commands[i];
            Command.bAdminOnly = bool(flagAdminOnlyCommand[i]);
            return;
        }
    }

    bStatus = False;
}

protected function CheckPermissions()
{
    if (Command.bAdminOnly && 
        !Sender.PlayerReplicationInfo.bAdmin && 
        !Sender.PlayerReplicationInfo.bSilentAdmin)
    {
        bStatus = False;
        Msg(MsgAccessDenied);
    }
}

protected function ProcessSettingsChangingCommand(out string Value)
{
    HandleChangeSettings(Value);
}

protected function HandleChangeSettings(out string Value)
{
    local int i;
    for (i = 0; i < Command.Settings.Length; i++)
    {
        HandleChangeSingleSetting(Command.Settings[i].Key, Args[0]);
    }

    Value = outer.GetPropertyText(Command.Settings[0].Key);
}

protected function HandleChangeSingleSetting(string SettingKey, string Value)
{
    outer.SetPropertyText(SettingKey, Value);
}

protected function ProcessInfoCommand()
{
    switch (Command.Alias)
    {
    case Commands[INFO_Help].Alias:
        Help();
        break;

    case Commands[INFO_Cfg].Alias:
        ShowConfig();
        break;

    default:
        bStatus = False;
    }
}

protected function Help()
{
    local CommandInfo cmd;
    local int i;

    for (i = 0; i < COMMANDS_COUNT; i++)
    {
        cmd = Commands[i];
        Msg(Prefix$cmd.Alias$" "$cmd.Signature$"  ::  "$cmd.Description);
    }
}

protected function ShowConfig()
{
    local string EnabledZeds, DisabledZeds, Skins;
    local bool bCurrentZedEnabled;
    local int i;

    for (i = 0; i < Command.Settings.Length; i++)
    {
        bCurrentZedEnabled = bool(outer.GetPropertyText(Command.Settings[i].Key));

        if (Command.Settings[i].Key == B_USE_ORIGINAL_ZED_SKINS_KEY)
        {
            Skins = string(bCurrentZedEnabled);
        }
        else if (bCurrentZedEnabled)
        {
            if (Len(EnabledZeds) == 0)
                EnabledZeds = Command.Settings[i].Id;
            else
                EnabledZeds $= ", "$Command.Settings[i].Id;
        }
        else
        {
            if (Len(DisabledZeds) == 0)
                DisabledZeds = Command.Settings[i].Id;
            else
                DisabledZeds $= ", "$Command.Settings[i].Id;
        }
    }

    Msg("Enabled Zeds: "$EnabledZeds);
    Msg("Disabled Zeds: "$DisabledZeds);
    Msg("Use Original Skins: "$Skins);
}

/*************************
 HELPERS
 *************************/

protected function string GetFullAlias(string CommandAlias)
{
    return Locs(Prefix$CommandAlias);
}

protected function string GetSuccessMessage(string SettingKey, string Value)
{
    local string transformedMessage;
    transformedMessage = MsgSuccessTemplate;

    ReplaceText(transformedMessage, TEMPLATE_KEY, SettingKey);
    ReplaceText(transformedMessage, TEMPLATE_VALUE, Value);

    return transformedMessage;
}

protected function Msg(string Message)
{
    Sender.TeamMessage(None, Message, 'Event');
}

defaultProperties
{
    bStatus=True

    Prefix="zeds."
    Commands(0)=(Alias="help",Description="Show Available Commands",Signature="< >",bAffectsZedConfig=False,bAdminOnly=False,SettingsText="",Settings=())
    Commands(1)=(Alias="cfg",Description="Show Current Config",Signature="< >",bAffectsZedConfig=False,bAdminOnly=False,SettingsText="",Settings=((Id="Original Skins",Key="bUseOriginalZedSkins"),(Id="Clot",Key="bReplaceClot"),(Id="Crawler",Key="bReplaceCrawler"),(Id="Gorefast",Key="bReplaceGorefast"),(Id="Stalker",Key="bReplaceStalker"),(Id="Scrake",Key="bReplaceScrake"),(Id="Fleshpound",Key="bReplaceFleshpound"),(Id="Bloat",Key="bReplaceBloat"),(Id="Siren",Key="bReplaceSiren"),(Id="Husk",Key="bReplaceHusk"),(Id="Boss",Key="bReplaceBoss")))
    Commands(2)=(Alias="skins",Description="Use Original ZEDs Skins",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bUseOriginalZedSkins",Settings=((Id="Original Skins",Key="bUseOriginalZedSkins")))
    Commands(3)=(Alias="clot",Description="Replace Clots",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceClot",Settings=((Id="Clot",Key="bReplaceClot")))
    Commands(4)=(Alias="crawl",Description="Replace Crawlers",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceCrawler",Settings=((Id="Crawler",Key="bReplaceCrawler")))
    Commands(5)=(Alias="gore",Description="Replace Gorefasts",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceGorefast",Settings=((Id="Gorefast",Key="bReplaceGorefast")))
    Commands(6)=(Alias="stalk",Description="Replace Stalkers",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceStalker",Settings=((Id="Stalker",Key="bReplaceStalker")))
    Commands(7)=(Alias="sc",Description="Replace Scrakes",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceScrake",Settings=((Id="Scrake",Key="bReplaceScrake")))
    Commands(8)=(Alias="fp",Description="Replace Fleshpounds",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceFleshpound",Settings=((Id="Fleshpound",Key="bReplaceFleshpound")))
    Commands(9)=(Alias="bloat",Description="Replace Bloats",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceBloat",Settings=((Id="Bloat",Key="bReplaceBloat")))
    Commands(10)=(Alias="siren",Description="Replace Sirens",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceSiren",Settings=((Id="Siren",Key="bReplaceSiren")))
    Commands(11)=(Alias="husk",Description="Replace Husks",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceHusk",Settings=((Id="Husk",Key="bReplaceHusk")))
    Commands(12)=(Alias="boss",Description="Replace Boss",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="bReplaceBoss",Settings=((Id="Boss",Key="bReplaceBoss")))
    Commands(13)=(Alias="all",Description="Replace All",Signature="< flag >",bAffectsZedConfig=True,bAdminOnly=False,SettingsText="All zeds replacement",Settings=((Id="Clot",Key="bReplaceClot"),(Id="Crawler",Key="bReplaceCrawler"),(Id="Gorefast",Key="bReplaceGorefast"),(Id="Stalker",Key="bReplaceStalker"),(Id="Scrake",Key="bReplaceScrake"),(Id="Fleshpound",Key="bReplaceFleshpound"),(Id="Bloat",Key="bReplaceBloat"),(Id="Siren",Key="bReplaceSiren"),(Id="Husk",Key="bReplaceHusk"),(Id="Boss",Key="bReplaceBoss")))

    MsgSuccessTemplate="%KEY% set to %VALUE%"
    MsgAccessDenied="Access Denied"
}
