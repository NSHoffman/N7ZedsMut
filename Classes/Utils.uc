class Utils extends Core.Object;

static function float FRatio(coerce float RateValue)
{
    return FMax(FMin(RateValue, 1.0), 0.0);
}

static function bool BChance(coerce float ChanceValue)
{
    local float ActualValue;
    ActualValue = FRand();

    return ChanceValue > 0 && ActualValue <= ChanceValue;
}

defaultProperties {}
