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
    mat.unit_cost = 2.16
    return mat
end

function Material(::Type{Val{:Copper}})
    mat = Material()
    mat.name = "Copper"
    mat.density = 8.96
    mat.unit_cost = 8.36
    return mat
end

function Material(::Type{Val{:FLiBe}}; temperature::Real = 500.0)
    mat = Material()
    mat.name = "FLiBe"
    mat.temperature = temperature
    mat.density = 2.214 - 4.2e-4*temperature
    mat.unit_cost = 43
    return mat
end

function Material(::Type{Val{:Lithium_Lead}}; temperature::Real = 500.0)
    mat = Material()
    mat.name = "Lithium-Lead"
    mat.temperature = temperature
    mat.density = 99.90*(0.1 - 16.8e-6*temperature) # density equation valid in the range 240-350 C, need to fix this
    mat.unit_cost = 25
    return mat
end

function Material(::Type{Val{:Nb3Sn}})
    mat = Material()
    mat.name = "Nb3Sn"
    mat.density = 8.69
    mat.unit_cost = 700
    return mat
end

function Material(::Type{Val{:NbTi}})
    mat = Material()
    mat.name = "NbTi"
    mat.density = 5.7
    mat.unit_cost = 100
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
    mat.unit_cost = 0.794
    return mat
end

function Material(::Type{Val{:Tungsten}})
    mat = Material()
    mat.name = "Tungsten"
    mat.density = 19.3
    mat.unit_cost = 31.2
    return mat
end

# Dispatch on symbol

function Material(name::Symbol, args...; kw...)
    return Material(Val{name}, args...; kw...)
end

