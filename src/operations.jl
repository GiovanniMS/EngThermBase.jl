#----------------------------------------------------------------------------------------------#
#                                     Same-Type Operations                                     #
#----------------------------------------------------------------------------------------------#

import Base: +, -

+(x::AMOUNTS) = x
-(x::AMOUNTS) = (typeof(x).name.wrapper)(-amt(x))


#----------------------------------------------------------------------------------------------#
#                               Same-Unit (Same-Base) Operations                               #
#----------------------------------------------------------------------------------------------#

# Energy fallback sum,sub of same-parameter ΔeAmt's
+(x::ΔeAmt{𝗽,𝘅,𝗯}, y::ΔeAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔeAmt(+(amt(x), amt(y)))
-(x::ΔeAmt{𝗽,𝘅,𝗯}, y::ΔeAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔeAmt(-(amt(x), amt(y)))

# Energy converting/promoting sum,sub of same-base amounts
+(x::ENERGYA{𝗽,𝘅,𝗯}, y::ENERGYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔeAmt(amt(x)), (x, y))...)...)
end
-(x::ENERGYA{𝗽,𝘅,𝗯}, y::ENERGYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    -(promote(map(x -> ΔeAmt(amt(x)), (x, y))...)...)
end


# Entropy fallback sum,sub of same-parameter ΔeAmt's
+(x::ΔsAmt{𝗽,𝘅,𝗯}, y::ΔsAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔsAmt(+(amt(x), amt(y)))
-(x::ΔsAmt{𝗽,𝘅,𝗯}, y::ΔsAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔsAmt(-(amt(x), amt(y)))

# Entropy converting/promoting sum,sub of same-base amounts
+(x::NTROPYA{𝗽,𝘅,𝗯}, y::NTROPYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔsAmt(amt(x)), (x, y)))...)
end
-(x::NTROPYA{𝗽,𝘅,𝗯}, y::NTROPYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    -(promote(map(x -> ΔsAmt(amt(x)), (x, y)))...)
end


# Fallback remaining same-{type,prec,exac,base} BasedAmt sub,sum
+(x::BasedAmt{𝗽,𝘅,𝗯}, y::BasedAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = BasedAmt(+(amt(x), amt(y)))
-(x::BasedAmt{𝗽,𝘅,𝗯}, y::BasedAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = BasedAmt(-(amt(x), amt(y)))

# Remaining BasedAmt promoting sum,sub of same-{type,base} amounts
+(x::BasedAmt{𝗽,𝘅,𝗯}, y::BasedAmt{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = +(promote(x, y)...)
-(x::BasedAmt{𝗽,𝘅,𝗯}, y::BasedAmt{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = -(promote(x, y)...)


# Fallback remaining same-{type,prec,exac} WholeAmt sub,sum
+(x::WholeAmt{𝗽,𝘅}, y::WholeAmt{𝗽,𝘅}) where {𝗽,𝘅} = WholeAmt(+(amt(x), amt(y)))
-(x::WholeAmt{𝗽,𝘅}, y::WholeAmt{𝗽,𝘅}) where {𝗽,𝘅} = WholeAmt(-(amt(x), amt(y)))

# Remaining WholeAmt promoting sum,sub of same-{type} amounts
+(x::WholeAmt{𝗽,𝘅}, y::WholeAmt{𝘀,𝘆}) where {𝗽,𝘀,𝘅,𝘆} = +(promote(x, y)...)
-(x::WholeAmt{𝗽,𝘅}, y::WholeAmt{𝘀,𝘆}) where {𝗽,𝘀,𝘅,𝘆} = -(promote(x, y)...)


# Currently, the dimensions of a `(GenericAmt{𝗽,𝘅} where {𝗽<:PREC,𝘅<:EXAC}).amt are unknown. One
# can ask whether to refactor the code, e.g., by adding a dimensions parameter `D` in the
# `GenericAmt` type (thus a `GenericAmt{𝗽,𝘅,D} where {𝗽<:PREC,𝘅<:EXAC} where D`). However, given
# the facts that (i) `Unitful` defines the +,- operations for `Quantity`'s of incompatible
# dimensions (raising a `DimensionError: xxx and yyy are not dimensionally compatible.` error),
# and therefore (ii) the pertinent exception is caught; and (iii) adding a `D` parameter would
# render `EngThermBase`'s `AMOUNTS` design non-uniform, incompatible dimension handlings is left
# to the underlying `Unitful` package to handle.

# Fallback remaining same-{type,prec,exac} GenericAmt sub,sum
+(x::GenericAmt{𝗽,𝘅}, y::GenericAmt{𝗽,𝘅}) where {𝗽,𝘅} = GenericAmt(+(amt(x), amt(y)))
-(x::GenericAmt{𝗽,𝘅}, y::GenericAmt{𝗽,𝘅}) where {𝗽,𝘅} = GenericAmt(-(amt(x), amt(y)))

# Remaining GenericAmt promoting sum,sub of same-{type} amounts
+(x::GenericAmt{𝗽,𝘅}, y::GenericAmt{𝘀,𝘆}) where {𝗽,𝘀,𝘅,𝘆} = +(promote(x, y)...)
-(x::GenericAmt{𝗽,𝘅}, y::GenericAmt{𝘀,𝘆}) where {𝗽,𝘀,𝘅,𝘆} = -(promote(x, y)...)


#----------------------------------------------------------------------------------------------#
#                                 Dimensions-based Conversions                                 #
#----------------------------------------------------------------------------------------------#

"""
`function AMT(x::Number)`\n
Generates the default `AMOUNTS` from `a`, based on its unit dimensions.  The eltype-undecorated
`Quantity` constructors are evoked, so that the resulting type precision is taken from the `x`
argument. This function is extensively used in operations that result in a unit change.
"""
function AMT(x::Number)
    X, D = float(real(x)), dimension(x)
    # --- GenericAmt default
    if      D == dimension(1);              _Amt(X)
    # --- WholeAmt
    elseif  D == dimension(u"K");           sysT(X)
    elseif  D == dimension(u"kPa");         sysP(X)
    elseif  D == dimension(u"m/s");         VELO(X)
    elseif  D == dimension(u"s");           time(X)
    elseif  D == dimension(u"m/s^2");       grav(X)
    elseif  D == dimension(u"m");           alti(X)
    # --- BasedAmt
    elseif  D == dimension(u"kg");          mAmt(X)
    elseif  D == dimension(u"kg/s");        mAmt(X)
    elseif  D == dimension(u"kg/kmol");     mAmt(X)
    elseif  D == dimension(u"kmol");        nAmt(X)
    elseif  D == dimension(u"kmol/s");      nAmt(X)
    elseif  D == dimension(u"kmol/kg");     nAmt(X)
    elseif  D == dimension(u"m^3");         vAmt(X)
    elseif  D == dimension(u"m^3/s");       vAmt(X)
    elseif  D == dimension(u"m^3/kg");      vAmt(X)
    elseif  D == dimension(u"m^3/kmol");    vAmt(X)
    elseif  D == dimension(u"kJ");          ΔeAmt(X)    # energy fallback
    elseif  D == dimension(u"kJ/s");        ΔeAmt(X)
    elseif  D == dimension(u"kJ/kg");       ΔeAmt(X)
    elseif  D == dimension(u"kJ/kmol");     ΔeAmt(X)
    elseif  D == dimension(u"kJ/K");        ΔsAmt(X)    # ntropy fallback
    elseif  D == dimension(u"kJ/K/s");      ΔsAmt(X)
    elseif  D == dimension(u"kJ/K/kg");     ΔsAmt(X)
    elseif  D == dimension(u"kJ/K/kmol");   ΔsAmt(X)
    # --- GenericAmt fallback
    else                                    _Amt(X)
    end
end

export AMT


#----------------------------------------------------------------------------------------------#
#                                    Products and Divisions                                    #
#----------------------------------------------------------------------------------------------#

import Base: *, /


