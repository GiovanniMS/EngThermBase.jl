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
+(x::ΔeAmt{𝗽,𝘅,𝗯}, y::ΔeAmt{𝗽,𝘅,𝗯}) = ΔeAmt(+(amt(x), amt(y)))
-(x::ΔeAmt{𝗽,𝘅,𝗯}, y::ΔeAmt{𝗽,𝘅,𝗯}) = ΔeAmt(-(amt(x), amt(y)))

# Energy converting/promoting sum,sub of same-base amounts
+(x::ENERGYA{𝗽,𝘅,𝗯}, y::ENERGYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔeAmt(amt(x)), (x, y)))...)
end
-(x::ENERGYA{𝗽,𝘅,𝗯}, y::ENERGYA{𝘀,𝘆,𝗯}) where {𝗽,𝘀,𝘅,𝘆,𝗯} = begin
    +(promote(map(x -> ΔeAmt(amt(x)), (x, y)))...)
end


