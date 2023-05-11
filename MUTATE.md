# N7Zeds Mutate API

## Description

This section explains usage of `mutate ...` console commands added with N7Zeds mutator in order to make the process of in-game configuration easier.

## Basics

Each command has a _Prefix_ and an _Alias_. The former is to avoid collisions with the commands from other mutators with the same name, the latter is the command name itself.
While **prefix can be changed** via `N7ZedsMut.ini` **the alias cannot**. Default prefix ends with `.`.

## Commands

The following are the commands with the default prefix `zeds.`:

1. `zeds.help` - Shows list of all available commands.
2. `zeds.cfg` - Shows current configuration settings.
3. `zeds.skins` - Toggles original skins usage.
4. `zeds.clot` - Toggles Clots replacement.
5. `zeds.crawl` - Toggles Crawlers replacement.
6. `zeds.gore` - Toggles Gorefasts replacement.
7. `zeds.stalk` - Toggles Stalkers replacement.
8. `zeds.sc` - Toggles Scrakes replacement.
9. `zeds.fp` - Toggles Fleshpounds replacement.
10. `zeds.bloat` - Toggles Bloats replacement.
11. `zeds.siren` - Toggles Sirens replacement.
12. `zeds.husk` - Toggles Husks replacement.
13. `zeds.boss` - Toggles Boss replacement.
14. `zeds.all` - Toggles all ZEDs replacement.

## Config Example

```ini
[N7ZedsMut.N7ZedsConfigMutateAPI]
; By default all commands are available to everyone
; Change value to 1 to make a command in question 'admin only'
flagAdminOnlyCommand[0]=0
flagAdminOnlyCommand[1]=0
flagAdminOnlyCommand[2]=0
flagAdminOnlyCommand[3]=0
flagAdminOnlyCommand[4]=0
flagAdminOnlyCommand[5]=0
flagAdminOnlyCommand[6]=0
flagAdminOnlyCommand[7]=0
flagAdminOnlyCommand[8]=0
flagAdminOnlyCommand[9]=0
flagAdminOnlyCommand[10]=0
flagAdminOnlyCommand[11]=0
flagAdminOnlyCommand[12]=0
flagAdminOnlyCommand[13]=0

; Commands prefix
Prefix=zeds.

; Template for success message
; %KEY% gets replaced with actual setting key
; %VALUE% gets replaced with True/False
MsgSuccessTemplate=%KEY% set to %VALUE%

; Access denied message used in admin only commands
MsgAccessDenied=Access Denied
```
