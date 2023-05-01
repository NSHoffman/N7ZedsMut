class N7_FleshpoundLight extends Engine.Light;

const HUE_Red = 255;
const HUE_Yellow = 36;

var protected bool bRed;

simulated function Tick(float DeltaTime)
{
    if (bRed && LightHue != HUE_Red)
        ChangeToRed();
    else if (!bRed && LightHue != HUE_Yellow)
        ChangeToYellow();

    super.Tick(DeltaTime);
}

simulated function ChangeToRed() 
{
    LightHue = HUE_Red;
    bRed = True;
}

simulated function ChangeToYellow() 
{
    LightHue = HUE_Yellow;
    bRed = False;
}

defaultProperties
{
    LightHue=HUE_Yellow
    LightSaturation=0
    LightBrightness=255.00000
    LightRadius=3.000000
    LightCone=255
    LightType=LT_Steady
    CollisionRadius=5.000000
    CollisionHeight=5.000000
    bMovable=True
    bStatic=False
    bDynamicLight=True
    bLightChanged=True
    bNoDelete=False
    bHidden=False
    Texture=None
}
