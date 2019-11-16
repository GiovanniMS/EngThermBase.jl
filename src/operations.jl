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
    +(promote(map(x -> ΔeAmt(amt(x)), (x, y)))...)
end
-(x::ENERGYA{𝗽,𝘅,𝗯}, y::ENERGYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔeAmt(amt(x)), (x, y)))...)
end


# Entropy fallback sum,sub of same-parameter ΔeAmt's
+(x::ΔsAmt{𝗽,𝘅,𝗯}, y::ΔsAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔsAmt(+(amt(x), amt(y)))
-(x::ΔsAmt{𝗽,𝘅,𝗯}, y::ΔsAmt{𝗽,𝘅,𝗯}) where {𝗽,𝘅,𝗯} = ΔsAmt(-(amt(x), amt(y)))

# Entropy converting/promoting sum,sub of same-base amounts
+(x::NTROPYA{𝗽,𝘅,𝗯}, y::NTROPYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔsAmt(amt(x)), (x, y)))...)
end
-(x::NTROPYA{𝗽,𝘅,𝗯}, y::NTROPYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔsAmt(amt(x)), (x, y)))...)
end


# Fallback remaining same-{type,prec,exac,base} BasedAmt sub,sum
+(x::𝖠{𝗽,𝘅,𝗯}, y::𝖠{𝗽,𝘅,𝗯}) where {𝖠<:BasedAmt,𝗽,𝘅,𝗯} = 𝖠(+(amt(x), amt(y)))
-(x::𝖠{𝗽,𝘅,𝗯}, y::𝖠{𝗽,𝘅,𝗯}) where {𝖠<:BasedAmt,𝗽,𝘅,𝗯} = 𝖠(-(amt(x), amt(y)))

# Remaining BasedAmt promoting sum,sub of same-{type,base} amounts
+(x::𝖠{𝗽,𝘅,𝗯}, y::𝖠{𝘀,𝘆,𝗯}) where {𝖠<:BasedAmt,𝗽,𝘀,𝘅,𝘆,𝗯} = +(promote(x, y)...)
-(x::𝖠{𝗽,𝘅,𝗯}, y::𝖠{𝘀,𝘆,𝗯}) where {𝖠<:BasedAmt,𝗽,𝘀,𝘅,𝘆,𝗯} = +(promote(x, y)...)

# Fallback remaining same-{type,prec,exac} WholeAmt sub,sum
+(x::𝖠{𝗽,𝘅}, y::𝖠{𝗽,𝘅}) where {𝖠<:WholeAmt,𝗽,𝘅} = 𝖠(+(amt(x), amt(y)))
-(x::𝖠{𝗽,𝘅}, y::𝖠{𝗽,𝘅}) where {𝖠<:WholeAmt,𝗽,𝘅} = 𝖠(-(amt(x), amt(y)))

# Fallback remaining same-{type,prec,exac} GenericAmt sub,sum
# ----------------------------------------------------------------------------------------------
# Currently, the dimensions of a `(GenericAmt{𝗽,𝘅} where {𝗽<:PREC,𝘅<:EXAC}).amt are unknown. One
# can ask whether to refactor the code, e.g., by adding a dimensions parameter `D` in the
# `GenericAmt` type (thus a `GenericAmt{𝗽,𝘅,D} where {𝗽<:PREC,𝘅<:EXAC} where D`). However, given
# the facts that (i) `Unitful` defines the +,- operations for `Quantity`'s of incompatible
# dimensions (raising a `DimensionError: xxx and yyy are not dimensionally compatible.` error),
# and therefore (ii) the pertinent exception is caught; and (iii) adding a `D` parameter would
# render `EngThermBase`'s `AMOUNTS` design non-uniform, incompatible dimension handlings is left
# to the underlying `Unitful` package to handle.
+(x::𝖠{𝗽,𝘅}, y::𝖠{𝗽,𝘅}) where {𝖠<:GenericAmt,𝗽,𝘅} = 𝖠(+(amt(x), amt(y))) # Underlying `Unitful`
-(x::𝖠{𝗽,𝘅}, y::𝖠{𝗽,𝘅}) where {𝖠<:GenericAmt,𝗽,𝘅} = 𝖠(-(amt(x), amt(y))) # handles exceptions.

# Remaining WholeAmt promoting sum,sub of same-{type} amounts
+(x::𝖠{𝗽,𝘅}, y::𝖠{𝘀,𝘆}) where {𝖠<:Union{WholeAmt,GenericAmt},𝗽,𝘀,𝘅,𝘆} = +(promote(x, y)...)
-(x::𝖠{𝗽,𝘅}, y::𝖠{𝘀,𝘆}) where {𝖠<:Union{WholeAmt,GenericAmt},𝗽,𝘀,𝘅,𝘆} = +(promote(x, y)...)





