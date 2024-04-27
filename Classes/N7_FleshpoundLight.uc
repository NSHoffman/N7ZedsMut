class N7_FleshpoundLight extends Engine.Light;

function ChangeToRed()
{
    LightHue = 255;
}

function ChangeToYellow()
{
    LightHue = 35;
}

defaultProperties
{
    LightHue=35
    LightSaturation=25
    LightBrightness=200.00000
    LightRadius=2.500000
    LightCone=255
    LightType=LT_SubtlePulse
    CollisionRadius=5.000000
    CollisionHeight=5.000000
    bMovable=True
    bStatic=False
    bDynamicLight=True
    bNoDelete=False
    bHidden=False
    Texture=None
}
