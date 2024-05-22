const IMAS_build_coil_techs = Union{IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}

Base.@kwdef mutable struct Material
    name::Union{String,Missing} = missing
    description::Union{String,Missing} = missing
    type::Union{Vector{IMAS.BuildLayerType},Missing} = missing
    density::Union{Function,Missing} = missing # kg/m^3
    coil_tech::Union{IMAS_build_coil_techs,Missing} = missing
    thermal_conductivity::Union{Function,Missing} = missing # W/m*K
    electrical_conductivity::Union{Function,Missing} = missing # S/m
    critical_current_density::Union{Function,Missing} = missing # A/m^2
    critical_magnetic_field::Union{Function,Missing} = missing # T/T
    cost_kg::Union{Float64,Missing} = missing # $/kg
    cost_m3::Union{Float64,Missing} = missing # $/m³
end

function Material(coil_tech::IMAS_build_coil_techs)
    return Material(coil_tech.material; coil_tech)
end

function cost_m3!(mat::Material)
    if mat.cost_kg == 0.0
        mat.cost_m3 = 0.0
    else
        mat.cost_m3 = mat.cost_kg .* mat.density(; temperature=295.13)
    end
end

function Material(::Type{Val{:aluminum}})
    mat = Material()
    mat.name = "aluminum"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 2.7e3
    mat.thermal_conductivity = (; temperature::Float64) -> (49503 * exp(-0.072 * temperature) + 216.88)
    mat.electrical_conductivity = (; temperature::Float64) -> 3.5e7
    mat.cost_kg = 2.16 # source: https://www.focus-economics.com/commodities/base-metals/
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:copper}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material()
    mat.coil_tech = coil_tech
    mat.name = "copper"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 8.96e3
    mat.thermal_conductivity = (; temperature::Float64) -> 420.13 - 0.068 * temperature # fitted from ITER Materials Design Limit Data, page 137 (IDM UID 222RLN)
    mat.electrical_conductivity = (; temperature::Float64) -> 5.96e7
    mat.cost_kg = 8.36 # source: https://www.focus-economics.com/commodities/base-metals/
    mat.critical_current_density = (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) -> 18.5e6 # A/m^2
    mat.critical_magnetic_field = (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) -> Inf
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:plasma}})
    mat = Material()
    mat.name = "plasma"
    mat.type = [IMAS._plasma_]
    mat.cost_kg = 0.0
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:flibe}})
    mat = Material()
    mat.name = "flibe"
    mat.type = [IMAS._blanket_]
    mat.density = (; temperature::Float64) -> (temperature - 273.15) * -0.425 + 2245.5 # fitted from Vidrio et al, J. Chem. Eng. Data 2022, 67, 12
    mat.cost_kg = 43.0 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:graphite}})
    mat = Material()
    mat.name = "graphite"
    mat.description = "Reactor grade carbon, graphite"
    mat.type = [IMAS._wall_]
    mat.density = (; temperature::Float64) -> 1.7e3
    mat.thermal_conductivity = (; temperature::Float64) -> 29815 * temperature^-1.5 + 0.704 # fitted from Paulatto et al, Phys. Rev. B, April 2013, Figure 14
    mat.electrical_conductivity = (; temperature::Float64) -> 3.3e2
    mat.cost_kg = 1.3 # source: https://businessanalytiq.com/procurementanalytics/index/graphite-price-index/
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:lithium_lead}})
    mat = Material()
    mat.name = "lithium_lead"
    mat.type = [IMAS._blanket_]
    mat.density = (; temperature::Float64) -> 10526.1 - 1.292 * temperature # fitted from  Khairulin et al, Int. Journal of Thermophysics 38(2)
    mat.cost_kg = 10.0 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:nb3sn}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material()
    mat.name = "nb3sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 8.69e3
    mat.cost_kg = 2301.5
    mat.coil_tech = coil_tech

    params_Nb3Sn = LTS_scaling(29330000, 28.45, 0.0739, 17.5, -0.7388, -0.5060, -0.0831, 0.8855, 2.169, 2.5, 0.0, 1.5, 2.2)
    fc = IMAS.fraction_conductor(coil_tech)
    mat.critical_current_density =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            LTS_Jcrit(params_Nb3Sn, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).J_c * fc # A/m^2
    mat.critical_magnetic_field =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            Bext / LTS_Jcrit(params_Nb3Sn, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).b # A/m^2

    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:nb3sn_iter}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material("nb3sn"; coil_tech)
    mat.name = "nb3sn_iter"
    return mat
end

function Material(::Type{Val{:nb3sn_kdemo}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material()
    mat.name = "nb3sn_kdemo"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 8.69e3
    mat.cost_kg = 2301.5
    mat.coil_tech = coil_tech

    fc = IMAS.fraction_conductor(coil_tech)
    mat.critical_current_density =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            nb3sn_kdemo_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).J_c * fc # A/m^2
    mat.critical_magnetic_field =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            Bext / nb3sn_kdemo_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).b # A/m^2

    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:nbti}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material()
    mat.name = "nbti"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 5.7e3
    mat.cost_kg = 100.0 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 11 

    params_NbTi = LTS_scaling(255.3e6, 14.67, -0.002e-2, 8.89, -0.0025, -0.0003, -0.0001, 1.341, 1.555, 2.274, 0.0, 1.758, 2.2) # Table 1, Journal of Phys: Conf. Series, 1559 (2020) 012063
    fc = IMAS.fraction_conductor(coil_tech)
    mat.critical_current_density =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            LTS_Jcrit(params_NbTi, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).J_c * fc # A/m^2
    mat.critical_magnetic_field =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            Bext / LTS_Jcrit(params_NbTi, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).b # A/m^2

    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:rebco}}; coil_tech::Union{Missing,IMAS_build_coil_techs}=missing)
    mat = Material()
    mat.name = "rebco"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = (; temperature::Float64) -> 6.3e3
    mat.cost_kg = 3174.6

    fc = IMAS.fraction_conductor(coil_tech)
    mat.critical_current_density =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            ReBCO_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).J_c * fc # A/m^2
    mat.critical_magnetic_field =
        (; coil_tech::IMAS_build_coil_techs=coil_tech, temperature::Float64=coil_tech.temperature, Bext::Float64) ->
            Bext / ReBCO_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, temperature).b # A/m^2

    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:steel}})
    mat = Material()
    mat.name = "steel"
    mat.type = [IMAS._cryostat_, IMAS._shield_]
    mat.density = (; temperature::Float64) -> 7.93e3
    mat.thermal_conductivity = (; temperature::Float64) -> 9.87 + 0.015 * temperature
    mat.electrical_conductivity = (; temperature::Float64) -> 1.45e6
    mat.cost_kg = 0.794 # source: https://www.focus-economics.com/commodities/base-metals/steel-usa/
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:tungsten}})
    mat = Material()
    mat.name = "tungsten"
    mat.type = [IMAS._wall_]
    mat.density = (; temperature::Float64) -> 19.3e3
    mat.thermal_conductivity = (; temperature::Float64) -> 204.45 - 0.11986 * temperature + 3.6e-5 * temperature^2 # fitted from ITER Materials Design Limit Data, page 226 (IDM UID 222RLN)
    mat.electrical_conductivity = (; temperature::Float64) -> 1.87e7
    mat.cost_kg = 31.2 # source: https://almonty.com/tungsten/demand-pricing/
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:vacuum}})
    mat = Material()
    mat.name = "vacuum"
    mat.type = [IMAS._gap_]
    mat.density = (; temperature::Float64=NaN) -> 0.0
    mat.cost_kg = 0.0
    cost_m3!(mat)
    return mat
end

function Material(::Type{Val{:water}})
    mat = Material()
    mat.name = "water"
    mat.type = [IMAS._vessel_]
    mat.density = (; temperature::Float64) -> 1.0e3
    mat.cost_kg = 0.0
    cost_m3!(mat)
    return mat
end
