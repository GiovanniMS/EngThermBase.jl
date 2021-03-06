#----------------------------------------------------------------------------------------------#
#                                    Amount Type Interface                                     #
#----------------------------------------------------------------------------------------------#

"""
`function deco end`\n
Interface to return a unique decorative `Symbol` from a method's argument type.
"""
function deco end

"""
`function ppu end`\n
Interface to pretty-print units.
"""
function ppu end

# A 191113-212130 benchmark showed amt(x) is faster than x.amt:
#
# ```julia-repl
# julia> u1 = u(1.0f0 ± 0.1f0, MO)
# ū₃₂: (1 ± 0.1) kJ/kmol
#
# julia> typeof(u1)
# uAmt{Float32,MM,MO}
#
# julia> @benchmark u1.amt
# ✂ ✂ ✂   median time:      26.918 ns (0.00% GC)   ✂ ✂ ✂
#
# julia> @benchmark amt(u1)
# ✂ ✂ ✂   median time:      16.710 ns (0.00% GC)   ✂ ✂ ✂
#
# ```

"""
`function amt end`\n
Interface to get an `AMOUNTS`' `:amt` field in a type-stable manner.
"""
function amt end

export deco, ppu, amt


#----------------------------------------------------------------------------------------------#
#                                     Generic Amount Type                                      #
#----------------------------------------------------------------------------------------------#

import Base: cp, convert
import Unicode: normalize
import Base: +, -, *, /

"""
Generic Amount type factory.
"""
function mkGenAmt(TYPE::Symbol,         # Type name:            :_Amt
                  SUPT::Symbol,         # Supertype:            :GenerAmt
                  SYMB::AbstractString, # Printing symbol:      "?"
                  WHAT::AbstractString, # Description:          "generic amounts"
                  DELT::Bool=false,     # Whether a Δ quantity
                 )
    # Constants
    i, f = DELT ? (3, 4) : (1, 2)
    𝑠SY = normalize((DELT ? "Δ" : "") * string(SYMB))
    # Documentation
    hiStr = tyArchy(eval(SUPT))
    dcStr = """
`struct $TYPE{𝗽<:PREC,𝘅<:EXAC} <: $SUPT{𝗽,𝘅}`\n
Precision-, and Exactness- parametric $WHAT amounts based in arbitrary units.\n
`$TYPE{𝗽,𝘅}` parameters are:\n
- Precision `𝗽<:Union{Float16,Float32,Float64,BigFloat}`;\n
- Exactness `𝘅<:Union{EX,MM}`, i.e., either a single, precise value or an uncertainty-bearing
  measurement, respectively;\n
A `$TYPE` can be natively constructed from the following argument types:\n
- A plain, unitless float;\n
- A plain, unitless `Measurement`; hence, any `AbstractFloat`;\n
- A `Quantity{AbstractFloat}` with any units.\n
## Hierarchy\n
`$(TYPE) <: $(hiStr)`
    """
    # @eval block
    @eval begin
        # Concrete type definition
        struct $TYPE{𝗽,𝘅} <: $SUPT{𝗽,𝘅}
            amt::UATY{𝗽} where 𝗽<:PREC
            # Inner, non-converting, parameter-determining constructors
            $TYPE(x::$TYPE{𝗽,𝘅}) where {𝗽<:PREC,𝘅<:EXAC} = new{𝗽,𝘅}(amt(x))
            $TYPE(x::Union{𝗽,UETY{𝗽}}) where 𝗽<:PREC = new{𝗽,EX}(_qty(x))
            $TYPE(x::Union{PMTY{𝗽},UMTY{𝗽}}) where 𝗽<:PREC = new{𝗽,MM}(_qty(x))
            # Inner, non-converting, fully-specified constructors
            (::Type{$TYPE{𝗽,EX}})(x::𝗽) where 𝗽<:PREC = new{𝗽,EX}(_qty(x))
            (::Type{$TYPE{𝗽,EX}})(x::PMTY{𝗽}) where 𝗽<:PREC = new{𝗽,EX}(_qty(x.val))
            (::Type{$TYPE{𝗽,MM}})(x::𝗽) where 𝗽<:PREC = new{𝗽,MM}(_qty(measurement(x)))
            (::Type{$TYPE{𝗽,MM}})(x::PMTY{𝗽}) where 𝗽<:PREC = new{𝗽,MM}(_qty(x))
        end
        # Type documentation
        @doc $dcStr $TYPE
        # Precision-changing external constructors
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,EX}) where {𝘀<:PREC,𝗽<:PREC} = begin
            $TYPE(𝘀(amt(x).val) * unit(amt(x)))
        end
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,MM}) where {𝘀<:PREC,𝗽<:PREC} = begin
            $TYPE(Measurement{𝘀}(amt(x).val) * unit(amt(x)))
        end
        # Precision+Exactness-changing external constructors
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,EX}) where {𝘀<:PREC,𝗽<:PREC} = begin
            $TYPE(𝘀(amt(x).val) * unit(amt(x)))
        end
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,MM}) where {𝘀<:PREC,𝗽<:PREC} = begin
            $TYPE(𝘀(amt(x).val.val) * unit(amt(x)))
        end
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,EX},
                              e::𝘀=𝘀(max(eps(𝘀), eps(amt(x).val)))) where {𝘀<:PREC,
                                                                           𝗽<:PREC} = begin
            $TYPE(measurement(𝘀(amt(x).val), e) * unit(amt(x)))
        end
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,MM}) where {𝘀<:PREC,𝗽<:PREC} = begin
            $TYPE(Measurement{𝘀}(amt(x).val) * unit(amt(x)))
        end
        # Type export
        export $TYPE
        # Type-stabler wrapped amount obtaining function
        amt(x::$TYPE{𝗽,EX}) where 𝗽<:PREC = x.amt::Quantity{𝗽}
        amt(x::$TYPE{𝗽,MM}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽}}
        # Type-specific functions
        deco(x::$TYPE{𝗽,𝘅} where {𝗽,𝘅}) = Symbol($𝑠SY)
        ppu(x::$TYPE{𝗽,𝘅} where {𝗽,𝘅}) = string(unit(amt(x)))
        # Conversions
        convert(::Type{$TYPE{𝘀,𝘅}},
                y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),𝘅}(y)
        end
        convert(::Type{$TYPE{𝘀,𝘆}},
                y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅)}(y)
        end
        # Promotion rules
        promote_rule(::Type{$TYPE{𝘀,𝘆}},
                     ::Type{$TYPE{𝗽,𝘅}}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅)}
        end
        # same-type sum,sub with Unitful promotion
        +(x::$TYPE{𝘀,𝘆}, y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE(+(amt(x), amt(y)))
        end
        -(x::$TYPE{𝘀,𝘆}, y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE(-(amt(x), amt(y)))
        end
        # scalar mul,div with Unitful promotion
        *(y::plnF{𝘀}, x::$TYPE{𝗽}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        *(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        /(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(/(amt(x), y))
        # Type-preserving scalar mul,div
        *(y::REAL, x::$TYPE{𝗽}) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        *(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        /(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(/(amt(x), 𝗽(y)))
    end
end

#----------------------------------------------------------------------------------------------#
#                                 Generic Amount Declarations                                  #
#----------------------------------------------------------------------------------------------#

# The fallback generic amount
mkGenAmt(:_Amt  , :GenerAmt , "?"   , "generic amounts"     , false )


#----------------------------------------------------------------------------------------------#
#                                  Whole Amount Type Factory                                   #
#----------------------------------------------------------------------------------------------#

"""
Whole Amount type factory.
"""
function mkWhlAmt(TYPE::Symbol,         # Type name:            :sysT
                  SUPT::Symbol,         # Supertype:            :WProperty
                  FNAM::Symbol,         # Function Name:        :T
                  SYMB::AbstractString, # Printing symbol:      "T"
                  UNIT::Unitful.Units,  # SY quantity units:    u"K"
                  USTR::AbstractString, # PrettyPrinting units: "K"
                  WHAT::AbstractString, # Description:          "temperature"
                  DELT::Bool=false,     # Whether a Δ quantity
                 )
    # Constants
    uSY = UNIT
    𝑢SY = typeof(uSY)
    𝑑SY = dimension(uSY)
    i, f = DELT ? (3, 4) : (1, 2)
    𝑠SY = normalize((DELT ? "Δ" : "") * string(SYMB))
    # Documentation
    hiStr = tyArchy(eval(SUPT))
    dcStr = """
`struct $TYPE{𝗽<:PREC,𝘅<:EXAC} <: $SUPT{𝗽,𝘅}`\n
Precision-, and Exactness- parametric $WHAT amounts based in $USTR.\n
`$TYPE{𝗽,𝘅}` parameters are:\n
- Precision `𝗽<:Union{Float16,Float32,Float64,BigFloat}`;\n
- Exactness `𝘅<:Union{EX,MM}`, i.e., either a single, precise value or an uncertainty-bearing
  measurement, respectively;\n
A `$TYPE` can be natively constructed from the following argument types:\n
- A plain, unitless float;\n
- A plain, unitless `Measurement`; hence, any `AbstractFloat`;\n
- A `Quantity{AbstractFloat}` with compatible units.\n
Constructors determine all parameters from their arguments.\n
## Hierarchy\n
`$(TYPE) <: $(hiStr)`
    """
    # @eval block
    @eval begin
        # Concrete type definition
        struct $TYPE{𝗽,𝘅} <: $SUPT{𝗽,𝘅}
            amt::UATY{𝗽,$𝑑SY,$𝑢SY} where 𝗽<:PREC
            # Inner, non-converting, parameter-determining constructors
            # ---------------------------------------------------------
            # Copy constructor
            $TYPE(x::$TYPE{𝗽,𝘅}) where {𝗽<:PREC,𝘅<:EXAC} = new{𝗽,𝘅}(amt(x))
            # Plain constructors enforce default units & avoid unit conversion
            $TYPE(x::𝗽) where 𝗽<:PREC = new{𝗽,EX}(_qty(x * $uSY))
            $TYPE(x::PMTY{𝗽}) where 𝗽<:PREC = new{𝗽,MM}(_qty(x * $uSY))
            # Quantity constructors have to perform unit conversion despite matching dimensions
            $TYPE(x::UETY{𝗽,$𝑑SY}) where 𝗽<:PREC = new{𝗽,EX}(_qty(uconvert($uSY, x)))
            $TYPE(x::UMTY{𝗽,$𝑑SY}) where 𝗽<:PREC = new{𝗽,MM}(_qty(uconvert($uSY, x)))
            # Inner, non-converting, fully-specified constructors
            # ---------------------------------------------------
            (::Type{$TYPE{𝗽,EX}})(x::𝗽) where 𝗽<:PREC = new{𝗽,EX}(_qty(x * $uSY))
            (::Type{$TYPE{𝗽,EX}})(x::PMTY{𝗽}) where 𝗽<:PREC = new{𝗽,EX}(_qty(x.val * $uSY))
            (::Type{$TYPE{𝗽,MM}})(x::𝗽) where 𝗽<:PREC = new{𝗽,MM}(_qty(measurement(x) * $uSY))
            (::Type{$TYPE{𝗽,MM}})(x::PMTY{𝗽}) where 𝗽<:PREC = new{𝗽,MM}(_qty(x * $uSY))
        end
        # Type documentation
        @doc $dcStr $TYPE
        # Precision-changing external constructors
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,EX}
                          ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(𝘀(amt(x).val))
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,MM}
                          ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(Measurement{𝘀}(amt(x).val))
        # Precision+Exactness-changing external constructors
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,EX}
                             ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(𝘀(amt(x).val))
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,MM}
                             ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(𝘀(amt(x).val.val))
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,EX},
                              e::𝘀=𝘀(max(eps(𝘀),eps(amt(x).val)))
                             ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(measurement(𝘀(amt(x).val), e))
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,MM}
                             ) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(Measurement{𝘀}(amt(x).val))
        # Type export
        export $TYPE
        # Type-stable wrapped amount obtaining function
        amt(x::$TYPE{𝗽,EX}) where 𝗽<:PREC = x.amt::Quantity{𝗽,$𝑑SY,$𝑢SY}
        amt(x::$TYPE{𝗽,MM}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽},$𝑑SY,$𝑢SY}
        # Type-specific functions
        deco(x::$TYPE{𝗽,𝘅} where {𝗽,𝘅}) = Symbol($𝑠SY)
        ppu(x::$TYPE{𝗽,𝘅} where {𝗽,𝘅}) = $USTR
        # Indirect construction from plain
        $FNAM(x::plnF) = $TYPE(x)
        $FNAM(x::REAL) = $TYPE(float(x))
        # Indirect construction from quantity
        $FNAM(x::UATY{𝗽,$𝑑SY}) where 𝗽<:PREC = $TYPE(x)
        $FNAM(x::uniR{𝗽,$𝑑SY}) where 𝗽<:REAL = $TYPE(float(x.val) * unit(x))
        export $FNAM
        # Conversions
        convert(::Type{$TYPE{𝘀,𝘅}},
                y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),𝘅}(y)
        end
        convert(::Type{$TYPE{𝘀,𝘆}},
                y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅)}(y)
        end
        # Promotion rules
        promote_rule(::Type{$TYPE{𝘀,𝘆}},
                     ::Type{$TYPE{𝗽,𝘅}}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅)}
        end
        # same-type sum,sub with Unitful promotion
        +(x::$TYPE{𝘀,𝘆}, y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE(+(amt(x), amt(y)))
        end
        -(x::$TYPE{𝘀,𝘆}, y::$TYPE{𝗽,𝘅}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC} = begin
            $TYPE(-(amt(x), amt(y)))
        end
        # scalar mul,div with Unitful promotion
        *(y::plnF{𝘀}, x::$TYPE{𝗽}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        *(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        /(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(/(amt(x), y))
        # Type-preserving scalar mul,div
        *(y::REAL, x::$TYPE{𝗽}) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        *(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        /(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(/(amt(x), 𝗽(y)))
    end
end


#----------------------------------------------------------------------------------------------#
#                           Thermodynamic Whole Amount Declarations                            #
#----------------------------------------------------------------------------------------------#

# Regular properties -- \bb#<TAB> velocity/speed function names
mkWhlAmt(:sysT  , :WProperty, :T    , "T"   , u"K"          , "K"       , "temperature"         , false )
mkWhlAmt(:sysP  , :WProperty, :P    , "P"   , u"kPa"        , "kPa"     , "pressure"            , false )
mkWhlAmt(:VELO  , :WProperty, :velo , "𝕍"   , u"√(kJ/kg)"   , "√kJ/kg"  , "velocity"            , false )
mkWhlAmt(:SPEE  , :WProperty, :spee , "𝕧"   , u"m/s"        , "m/s"     , "speed"               , false )

# Regular unranked -- \sans#<TAB> function names
mkWhlAmt(:TIME  , :WUnranked, :TIME , "𝗍"   , u"s"          , "s"       , "time"                , false )
mkWhlAmt(:grav  , :WUnranked, :grav , "𝗀"   , u"m/s^2"      , "m/s²"    , "gravity"             , false )
mkWhlAmt(:alti  , :WUnranked, :alti , "𝗓"   , u"m"          , "m"       , "altitude"            , false )


#----------------------------------------------------------------------------------------------#
#                                  Based Amount Type Factory                                   #
#----------------------------------------------------------------------------------------------#

"""
Based Amount type factory.
"""
function mkBasAmt(TYPE::Symbol,         # Type Name:            :uAmt
                  SUPT::Symbol,         # Supertype:            :BProperty
                  FNAM::Symbol,         # Function Name:        :u
                  SYMB::AbstractString, # Printing symbol:      "U"
                  UNIT::Unitful.Units,  # SY quantity units:    u"kJ"
                  USTR::AbstractString, # PrettyPrinting units: "K"
                  WHAT::AbstractString, # Description:          "internal energy"
                  DELT::Bool=false;     # Whether a Δ quantity
                  bsym::NTuple{4,Symbol}=(:none,:none,:none,:none)
                 )
    # Constants
    uSY = UNIT
    uDT = UNIT / u"s"
    uMA = UNIT / u"kg"
    uMO = UNIT / u"kmol"
    𝑢SY = typeof(uSY)
    𝑢DT = typeof(uDT)
    𝑢MA = typeof(uMA)
    𝑢MO = typeof(uMO)
    𝑑SY = dimension(uSY)
    𝑑DT = dimension(uDT)
    𝑑MA = dimension(uMA)
    𝑑MO = dimension(uMO)
    i, f = DELT ? (3, 4) : (1, 2)
    𝑠SY = bsym[1] == :none ?
        normalize((DELT ? "Δ" : "") * uppercase(string(SYMB))) :
        string(bsym[1])
    𝑠DT = bsym[2] == :none ?
        normalize(string(𝑠SY[1:i], "\u0307", 𝑠SY[f:end])) :
        string(bsym[2])
    𝑠MA = bsym[3] == :none ?
        normalize((DELT ? "Δ" : "") * lowercase(string(SYMB))) :
        string(bsym[3])
    𝑠MO = bsym[4] == :none ?
        normalize(string(𝑠MA[1:i], "\u0304", 𝑠MA[f:end])) :
        string(bsym[4])
    # Documentation
    hiStr = tyArchy(eval(SUPT))
    dcStr = """
`struct $TYPE{𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE} <: $SUPT{𝗽,𝘅,𝗯}`\n
Precision-, Exactness-, and Base- parametric $WHAT amounts based in $USTR.\n
`$TYPE{𝗽,𝘅,𝗯}` parameters are:\n
- Precision `𝗽<:Union{Float16,Float32,Float64,BigFloat}`;\n
- Exactness `𝘅<:Union{EX,MM}`, i.e., either a single, precise value or an uncertainty-bearing
  measurement, respectively;\n
- Thermodynamic base `𝗯<:Union{SY,DT,MA,MO}` respectively for system, rate, mass, or molar
  quantities, respectively in units of $(uSY), $(uDT), $(uMA), or $(uMO).\n
A `$TYPE` can be natively constructed from the following argument types:\n
- A plain, unitless float;\n
- A plain, unitless `Measurement`; hence, any `AbstractFloat`;\n
- A `Quantity{AbstractFloat}` with compatible units.\n
Constructors determine parameters from their arguments. `Quantity` constructors do not need a
base argument. Plain, `AbstractFloat` ones require the base argument.\n
## Hierarchy\n
`$(TYPE) <: $(hiStr)`
    """
    # @eval block
    @eval begin
        # Concrete type definition
        struct $TYPE{𝗽,𝘅,𝗯} <: $SUPT{𝗽,𝘅,𝗯}
            amt::Union{UATY{𝗽,$𝑑SY,$𝑢SY},UATY{𝗽,$𝑑DT,$𝑢DT},
                       UATY{𝗽,$𝑑MA,$𝑢MA},UATY{𝗽,$𝑑MO,$𝑢MO}} where 𝗽<:PREC
            # Inner, non-converting, parameter-determining constructors
            # ---------------------------------------------------------
            # Copy constructor
            $TYPE(x::$TYPE{𝗽,𝘅,𝗯}) where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE} = new{𝗽,𝘅,𝗯}(amt(x))
            # Plain constructors enforce default units & avoid unit conversion
            # Plain Exact (𝗽<:PREC) float constructors
            $TYPE(x::𝗽, ::Type{SY}) where 𝗽<:PREC = new{𝗽,EX,SY}(_qty(x * $uSY))
            $TYPE(x::𝗽, ::Type{DT}) where 𝗽<:PREC = new{𝗽,EX,DT}(_qty(x * $uDT))
            $TYPE(x::𝗽, ::Type{MA}) where 𝗽<:PREC = new{𝗽,EX,MA}(_qty(x * $uMA))
            $TYPE(x::𝗽, ::Type{MO}) where 𝗽<:PREC = new{𝗽,EX,MO}(_qty(x * $uMO))
            # Plain Measurement (PMTY) constructors
            $TYPE(x::PMTY{𝗽}, ::Type{SY}) where 𝗽<:PREC = new{𝗽,MM,SY}(_qty(x * $uSY))
            $TYPE(x::PMTY{𝗽}, ::Type{DT}) where 𝗽<:PREC = new{𝗽,MM,DT}(_qty(x * $uDT))
            $TYPE(x::PMTY{𝗽}, ::Type{MA}) where 𝗽<:PREC = new{𝗽,MM,MA}(_qty(x * $uMA))
            $TYPE(x::PMTY{𝗽}, ::Type{MO}) where 𝗽<:PREC = new{𝗽,MM,MO}(_qty(x * $uMO))
            # Quantity constructors have to perform unit conversion despite matching dimensions
            # United Exact (UETY) constructors
            $TYPE(x::UETY{𝗽,$𝑑SY}) where 𝗽<:PREC = new{𝗽,EX,SY}(_qty(uconvert($uSY, x)))
            $TYPE(x::UETY{𝗽,$𝑑DT}) where 𝗽<:PREC = new{𝗽,EX,DT}(_qty(uconvert($uDT, x)))
            $TYPE(x::UETY{𝗽,$𝑑MA}) where 𝗽<:PREC = new{𝗽,EX,MA}(_qty(uconvert($uMA, x)))
            $TYPE(x::UETY{𝗽,$𝑑MO}) where 𝗽<:PREC = new{𝗽,EX,MO}(_qty(uconvert($uMO, x)))
            # United Measurement (UMTY) constructors
            $TYPE(x::UMTY{𝗽,$𝑑SY}) where 𝗽<:PREC = new{𝗽,MM,SY}(_qty(uconvert($uSY, x)))
            $TYPE(x::UMTY{𝗽,$𝑑DT}) where 𝗽<:PREC = new{𝗽,MM,DT}(_qty(uconvert($uDT, x)))
            $TYPE(x::UMTY{𝗽,$𝑑MA}) where 𝗽<:PREC = new{𝗽,MM,MA}(_qty(uconvert($uMA, x)))
            $TYPE(x::UMTY{𝗽,$𝑑MO}) where 𝗽<:PREC = new{𝗽,MM,MO}(_qty(uconvert($uMO, x)))
            # Inner, non-converting, fully-specified constructors
            # ---------------------------------------------------
            # SY-based constructors
            (::Type{$TYPE{𝗽,EX,SY}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,EX,SY}(_qty(             x * $uSY))
            end
            (::Type{$TYPE{𝗽,EX,SY}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,EX,SY}(_qty(         x.val * $uSY))
            end
            (::Type{$TYPE{𝗽,MM,SY}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,MM,SY}(_qty(measurement(x) * $uSY))
            end
            (::Type{$TYPE{𝗽,MM,SY}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,MM,SY}(_qty(             x * $uSY))
            end
            # DT-based constructors
            (::Type{$TYPE{𝗽,EX,DT}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,EX,DT}(_qty(             x * $uDT))
            end
            (::Type{$TYPE{𝗽,EX,DT}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,EX,DT}(_qty(         x.val * $uDT))
            end
            (::Type{$TYPE{𝗽,MM,DT}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,MM,DT}(_qty(measurement(x) * $uDT))
            end
            (::Type{$TYPE{𝗽,MM,DT}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,MM,DT}(_qty(             x * $uDT))
            end
            # MA-based constructors
            (::Type{$TYPE{𝗽,EX,MA}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,EX,MA}(_qty(             x * $uMA))
            end
            (::Type{$TYPE{𝗽,EX,MA}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,EX,MA}(_qty(         x.val * $uMA))
            end
            (::Type{$TYPE{𝗽,MM,MA}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,MM,MA}(_qty(measurement(x) * $uMA))
            end
            (::Type{$TYPE{𝗽,MM,MA}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,MM,MA}(_qty(             x * $uMA))
            end
            # MO-based constructors
            (::Type{$TYPE{𝗽,EX,MO}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,EX,MO}(_qty(             x * $uMO))
            end
            (::Type{$TYPE{𝗽,EX,MO}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,EX,MO}(_qty(         x.val * $uMO))
            end
            (::Type{$TYPE{𝗽,MM,MO}})(x::𝗽) where 𝗽<:PREC = begin
                new{𝗽,MM,MO}(_qty(measurement(x) * $uMO))
            end
            (::Type{$TYPE{𝗽,MM,MO}})(x::PMTY{𝗽}) where 𝗽<:PREC = begin
                new{𝗽,MM,MO}(_qty(             x * $uMO))
            end
        end
        # Type documentation
        @doc $dcStr $TYPE
        # Precision-changing external constructors
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,EX,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(𝘀(amt(x).val), 𝗯)
        end
        (::Type{$TYPE{𝘀}})(x::$TYPE{𝗽,MM,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(Measurement{𝘀}(amt(x).val), 𝗯)
        end
        # Precision+Exactness-changing external constructors
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,EX,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(𝘀(amt(x).val), 𝗯)
        end
        (::Type{$TYPE{𝘀,EX}})(x::$TYPE{𝗽,MM,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(𝘀(amt(x).val.val), 𝗯)
        end
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,EX,𝗯},
                            e::𝘀=𝘀(max(eps(𝘀),eps(amt(x).val)))
                            ) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(measurement(𝘀(amt(x).val), e), 𝗯)
        end
        (::Type{$TYPE{𝘀,MM}})(x::$TYPE{𝗽,MM,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝗯<:BASE} = begin
            $TYPE(Measurement{𝘀}(amt(x).val), 𝗯)
        end
        # Type export
        export $TYPE
        # Type-stable wrapped amount obtaining function
        amt(x::$TYPE{𝗽,EX,SY}) where 𝗽<:PREC = x.amt::Quantity{𝗽,$𝑑SY,$𝑢SY}
        amt(x::$TYPE{𝗽,EX,DT}) where 𝗽<:PREC = x.amt::Quantity{𝗽,$𝑑DT,$𝑢DT}
        amt(x::$TYPE{𝗽,EX,MA}) where 𝗽<:PREC = x.amt::Quantity{𝗽,$𝑑MA,$𝑢MA}
        amt(x::$TYPE{𝗽,EX,MO}) where 𝗽<:PREC = x.amt::Quantity{𝗽,$𝑑MO,$𝑢MO}
        amt(x::$TYPE{𝗽,MM,SY}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽},$𝑑SY,$𝑢SY}
        amt(x::$TYPE{𝗽,MM,DT}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽},$𝑑DT,$𝑢DT}
        amt(x::$TYPE{𝗽,MM,MA}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽},$𝑑MA,$𝑢MA}
        amt(x::$TYPE{𝗽,MM,MO}) where 𝗽<:PREC = x.amt::Quantity{Measurement{𝗽},$𝑑MO,$𝑢MO}
        # Type-specific functions
        deco(x::$TYPE{𝗽,𝘅,SY} where {𝗽,𝘅}) = Symbol($𝑠SY)
        deco(x::$TYPE{𝗽,𝘅,DT} where {𝗽,𝘅}) = Symbol($𝑠DT)
        deco(x::$TYPE{𝗽,𝘅,MA} where {𝗽,𝘅}) = Symbol($𝑠MA)
        deco(x::$TYPE{𝗽,𝘅,MO} where {𝗽,𝘅}) = Symbol($𝑠MO)
        ppu(x::$TYPE{𝗽,𝘅,SY} where {𝗽,𝘅}) = $USTR
        ppu(x::$TYPE{𝗽,𝘅,DT} where {𝗽,𝘅}) = $USTR * "/s"
        ppu(x::$TYPE{𝗽,𝘅,MA} where {𝗽,𝘅}) = $USTR * "/kg"
        ppu(x::$TYPE{𝗽,𝘅,MO} where {𝗽,𝘅}) = $USTR * "/kmol"
        # Indirect construction from plain
        $FNAM(x::plnF, b::Type{𝗯}=DEF[:IB]) where 𝗯<:BASE = $TYPE(x, b)
        $FNAM(x::REAL, b::Type{𝗯}=DEF[:IB]) where 𝗯<:BASE = $TYPE(float(x), b)
        # Indirect construction from quantity
        $FNAM(x::Union{UATY{𝗽,$𝑑SY},UATY{𝗽,$𝑑DT},
                       UATY{𝗽,$𝑑MA},UATY{𝗽,$𝑑MO}}) where 𝗽<:PREC = begin
            $TYPE(x)
        end
        $FNAM(x::Union{uniR{𝗽,$𝑑SY},uniR{𝗽,$𝑑DT},
                       uniR{𝗽,$𝑑MA},uniR{𝗽,$𝑑MO}}) where 𝗽<:REAL = begin
            $TYPE(float(x.val) * unit(x))
        end
        export $FNAM
        # Conversions - Change of base is _not_ a conversion
        # Same {EXAC,BASE}, {PREC}- conversion
        convert(::Type{$TYPE{𝘀,𝘅,𝗯}},
                y::$TYPE{𝗽,𝘅,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE} = begin
            $TYPE{promote_type(𝘀,𝗽),𝘅}(y)
        end
        # Same {BASE}, {PREC,EXAC}- conversion
        convert(::Type{$TYPE{𝘀,𝘆,𝗯}},
                y::$TYPE{𝗽,𝘅,𝗯}) where {𝘀<:PREC,𝗽<:PREC,𝘆<:EXAC,𝘅<:EXAC,𝗯<:BASE} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅)}(y)
        end
        # Promotion rules
        promote_rule(::Type{$TYPE{𝘀,𝘆,𝗯}},
                     ::Type{$TYPE{𝗽,𝘅,𝗯}}) where {𝘀<:PREC,𝗽<:PREC,
                                                  𝘆<:EXAC,𝘅<:EXAC,𝗯<:BASE} = begin
            $TYPE{promote_type(𝘀,𝗽),promote_type(𝘆,𝘅),𝗯}
        end
        # same-type sum,sub with Unitful promotion
        +(x::$TYPE{𝘀,𝘆,𝗯}, y::$TYPE{𝗽,𝘅,𝗯}) where {𝘀<:PREC,𝗽<:PREC,
                                                   𝘆<:EXAC,𝘅<:EXAC,
                                                   𝗯<:BASE} = begin
            $TYPE(+(amt(x), amt(y)))
        end
        -(x::$TYPE{𝘀,𝘆,𝗯}, y::$TYPE{𝗽,𝘅,𝗯}) where {𝘀<:PREC,𝗽<:PREC,
                                                   𝘆<:EXAC,𝘅<:EXAC,
                                                   𝗯<:BASE} = begin
            $TYPE(-(amt(x), amt(y)))
        end
        # scalar mul,div with Unitful promotion
        *(y::plnF{𝘀}, x::$TYPE{𝗽}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        *(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(*(amt(x), y))
        /(x::$TYPE{𝗽}, y::plnF{𝘀}) where {𝘀<:PREC,𝗽<:PREC} = $TYPE(/(amt(x), y))
        # Type-preserving scalar mul,div
        *(y::REAL, x::$TYPE{𝗽}) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        *(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(*(amt(x), 𝗽(y)))
        /(x::$TYPE{𝗽}, y::REAL) where 𝗽<:PREC = $TYPE(/(amt(x), 𝗽(y)))
    end
end


#----------------------------------------------------------------------------------------------#
#                           Thermodynamic Amount Group Declarations                            #
#----------------------------------------------------------------------------------------------#

# Mass / Mass fraction anomalous
mkBasAmt(:mAmt  , :BProperty, :m    , "m"   , u"kg"         , "kg"      , "mass"                , false , bsym=(:m , :ṁ , :mf, :M))
# Chemical amount / Molar fraction anomalous
mkBasAmt(:nAmt  , :BProperty, :N    , "N"   , u"kmol"       , "kmol"    , "chemical amount"     , false , bsym=(:N , :Ṅ , :n , :y))
# Gas constant / System constant anomalous
mkBasAmt(:RAmt  , :BProperty, :R    , "mR"  , u"kJ/K"       , "kJ/K"    , "gas constant"        , false , bsym=(:mR, :ṁR, :R , :R̄))
# Plank function anomalous
mkBasAmt(:rAmt  , :BProperty, :r    , "mr"  , u"kJ/K"       , "kJ/K"    , "Planck function"     , false , bsym=(:mr, :ṁr, :r , :r̄))

# Regular properties
mkBasAmt(:vAmt  , :BProperty, :v    , "V"   , u"m^3"        , "m³"      , "volume"              , false )
mkBasAmt(:uAmt  , :BProperty, :u    , "U"   , u"kJ"         , "kJ"      , "internal energy"     , false )
mkBasAmt(:hAmt  , :BProperty, :h    , "H"   , u"kJ"         , "kJ"      , "enthalpy"            , false )
mkBasAmt(:gAmt  , :BProperty, :g    , "G"   , u"kJ"         , "kJ"      , "Gibbs energy"        , false )
mkBasAmt(:aAmt  , :BProperty, :a    , "A"   , u"kJ"         , "kJ"      , "Helmholtz energy"    , false )
mkBasAmt(:eAmt  , :BProperty, :e    , "E"   , u"kJ"         , "kJ"      , "total energy"        , false )
mkBasAmt(:ekAmt , :BProperty, :ek   , "Ek"  , u"kJ"         , "kJ"      , "kinetic energy"      , false )
mkBasAmt(:epAmt , :BProperty, :ep   , "Ep"  , u"kJ"         , "kJ"      , "potential energy"    , false )
mkBasAmt(:sAmt  , :BProperty, :s    , "S"   , u"kJ/K"       , "kJ/K"    , "entropy"             , false )
mkBasAmt(:cpAmt , :BProperty, :cp   , "Cp"  , u"kJ/K"       , "kJ/K"    , "iso-P specific heat" , false )
mkBasAmt(:cvAmt , :BProperty, :cv   , "Cv"  , u"kJ/K"       , "kJ/K"    , "iso-v specific heat" , false )
mkBasAmt(:jAmt  , :BProperty, :j    , "J"   , u"kJ/K"       , "kJ/K"    , "Massieu function"    , false )

# Regular interactions
mkBasAmt(:qAmt  , :BInteract, :q    , "Q"   , u"kJ"         , "kJ"      , "heat"                , false )
mkBasAmt(:wAmt  , :BInteract, :w    , "W"   , u"kJ"         , "kJ"      , "work"                , false )
mkBasAmt(:ΔeAmt , :BInteract, :Δe   , "E"   , u"kJ"         , "kJ"      , "energy variation"    , true  )
mkBasAmt(:ΔsAmt , :BInteract, :Δs   , "S"   , u"kJ/K"       , "kJ/K"    , "entropy variation"   , true  )


#----------------------------------------------------------------------------------------------#
#                                      AMOUNT Type Unions                                      #
#----------------------------------------------------------------------------------------------#

# Unions of amounts of like units and thermodynamic classification, for same-unit operations

# --- energy
"""
`ENERGYP{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Energy property type union.
"""
ENERGYP{𝗽,𝘅,𝗯} = Union{uAmt{𝗽,𝘅,𝗯},hAmt{𝗽,𝘅,𝗯},
                       gAmt{𝗽,𝘅,𝗯},aAmt{𝗽,𝘅,𝗯},
                       eAmt{𝗽,𝘅,𝗯},ekAmt{𝗽,𝘅,𝗯},
                       epAmt{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}

"""
`ENERGYI{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Energy interaction type union.
"""
ENERGYI{𝗽,𝘅,𝗯} = Union{qAmt{𝗽,𝘅,𝗯},wAmt{𝗽,𝘅,𝗯},
                       ΔeAmt{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}

"""
`ENERGYA{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Energy amount type union.
"""
ENERGYA{𝗽,𝘅,𝗯} = Union{ENERGYP{𝗽,𝘅,𝗯},ENERGYI{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}


# --- entropy
"""
`NTROPYP{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Entropy property type union.
"""
NTROPYP{𝗽,𝘅,𝗯} = Union{RAmt{𝗽,𝘅,𝗯},rAmt{𝗽,𝘅,𝗯},
                       sAmt{𝗽,𝘅,𝗯},jAmt{𝗽,𝘅,𝗯},
                       cpAmt{𝗽,𝘅,𝗯},cvAmt{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}

"""
`NTROPYI{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Entropy interaction type union.
"""
NTROPYI{𝗽,𝘅,𝗯} = Union{ΔsAmt{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}

"""
`NTROPYA{𝗽,𝘅,𝗯} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}`\n
Entropy amount type union.
"""
NTROPYA{𝗽,𝘅,𝗯} = Union{NTROPYP{𝗽,𝘅,𝗯},NTROPYI{𝗽,𝘅,𝗯}} where {𝗽<:PREC,𝘅<:EXAC,𝗯<:BASE}


# --- velocity
"""
`VELOCYP{𝗽,𝘅} where {𝗽<:PREC,𝘅<:EXAC}`\n
Velocity property type union.
"""
VELOCYP{𝗽,𝘅,𝗯} = Union{VELO{𝗽,𝘅},SPEE{𝗽,𝘅}} where {𝗽<:PREC,𝘅<:EXAC}


#----------------------------------------------------------------------------------------------#
#                                       Pretty Printing                                        #
#----------------------------------------------------------------------------------------------#

import Base: show
import Formatting: sprintf1

# Auxiliar method
function subscript(x::Int)
    asSub(c::Char) = Char(Int(c) - Int('0') + Int('₀'))
    map(asSub, "$(x)")
end

# Precision decoration
pDeco(::Type{Float16})  = DEF[:showPrec] ? subscript(16) : ""
pDeco(::Type{Float32})  = DEF[:showPrec] ? subscript(32) : ""
pDeco(::Type{Float64})  = DEF[:showPrec] ? subscript(64) : ""
pDeco(::Type{BigFloat}) = DEF[:showPrec] ? subscript(precision(BigFloat)) : ""

# Custom printing
Base.show(io::IO, x::AMOUNTS{𝗽,EX}) where 𝗽<:PREC = begin
    if DEF[:pprint]
        print(io,
            "$(string(deco(x)))$(pDeco(𝗽)): ",
            sprintf1("%.$(DEF[:showSigD])g", amt(x).val),
            " ", ppu(x))
    else
        Base.show_default(io, x)
    end
end

Base.show(io::IO, x::AMOUNTS{𝗽,MM}) where 𝗽<:PREC = begin
    if DEF[:pprint]
        print(io,
            "$(string(deco(x)))$(pDeco(𝗽)): (",
            sprintf1("%.$(DEF[:showSigD])g", amt(x).val.val),
            " ± ",
            sprintf1("%.2g", amt(x).val.err),
            ") ", ppu(x))
    else
        Base.show_default(io, x)
    end
end


