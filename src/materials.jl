Base.@kwdef mutable struct Material
    name::Union{String, Missing} = missing 
    density::Union{Real, Missing} = missing # g/cm^3
    temperature::Union{Real, Missing} = missing # C
    unit_cost::Union{Real, Missing} = missing # $/kg
end

function Material(::Type{Val{:Aluminum}})
    mat = Material()
    mat.name = "Aluminum"
    mat.density = 2.7
    mat.unit_cost = 2.16 # source: https://www.focus-economics.com/commodities/base-metals/
    return mat
end

function Material(::Type{Val{:Copper}})
    mat = Material()
    mat.name = "Copper"
    mat.density = 8.96
    mat.unit_cost = 8.36 # source: https://www.focus-economics.com/commodities/base-metals/
    return mat
end

function Material(::Type{Val{:FLiBe}}; temperature::Real = 500.0)
    mat = Material()
    mat.name = "FLiBe"
    mat.temperature = temperature
    mat.density = 2.214 - 4.2e-4*temperature
    mat.unit_cost = 43 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    return mat
end

function Material(::Type{Val{:Graphite}};)
    mat = Material()
    mat.name = "Carbon, Graphite (reactor grade)"
    mat.density = 1.7
    mat.unit_cost = 1.3 # source: https://businessanalytiq.com/procurementanalytics/index/graphite-price-index/
    return mat
end

function Material(::Type{Val{:Lithium_Lead}}; temperature::Real = 500.0)
    mat = Material()
    mat.name = "Lithium-Lead"
    mat.temperature = temperature
    mat.density = 99.90*(0.1 - 16.8e-6*temperature) # density equation valid in the range 240-350 C, need to fix this
    mat.unit_cost = 10 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    return mat
end

function Material(::Type{Val{:Nb3Sn}})
    mat = Material()
    mat.name = "Nb3Sn"
    mat.density = 8.69
    mat.unit_cost = 700 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 13
    return mat
end

function Material(::Type{Val{:NbTi}})
    mat = Material()
    mat.name = "NbTi"
    mat.density = 5.7
    mat.unit_cost = 100 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 11 
    return mat
end

function Material(::Type{Val{:ReBCO}})
    mat = Material()
    mat.name = "ReBCO"
    mat.density = 6.3
    mat.unit_cost = 7000
    return mat
end

function Material(::Type{Val{:Steel}})
    mat = Material()
    mat.name = "Steel, Stainless 316"
    mat.density = 7.93
    mat.unit_cost = 0.794 # source: https://www.focus-economics.com/commodities/base-metals/steel-usa/
    return mat
end

function Material(::Type{Val{:Tungsten}})
    mat = Material()
    mat.name = "Tungsten"
    mat.density = 19.3
    mat.unit_cost = 31.2 # source: https://almonty.com/tungsten/demand-pricing/
    return mat
end

# Dispatch on symbol

function Material(name::Symbol, args...; kw...)
    return Material(Val{name}, args...; kw...)
end

