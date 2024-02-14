Base.@kwdef mutable struct Material
    name::Union{String,Missing} = missing
    description::Union{String,Missing} = missing
    type::Union{Vector{IMAS.BuildLayerType},Missing} = missing
    density::Union{Real,Missing} = missing # kg/m^3
    temperature::Union{Real,Missing} = missing # K
    thermal_conductivity::Union{Real,Missing} = missing # W/m*K
    electrical_conductivity::Union{Real,Missing} = missing # S/m
    critical_current_density::Union{Real,Missing} = missing # A/m^2
    critical_magnetic_field::Union{Real,Missing} = missing # T/T
    unit_cost::Union{Real,Missing} = missing # $/kg
end


function Material(::Type{Val{:aluminum}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "aluminum"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 2.7e3
    mat.thermal_conductivity = 49503 * exp(-0.072 * temperature) + 216.88
    mat.electrical_conductivity = 3.5e7
    mat.unit_cost = 2.16 # source: https://www.focus-economics.com/commodities/base-metals/
    return mat
end

function Material(::Type{Val{:copper}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "copper"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 8.96e3
    mat.thermal_conductivity = 420.13 - 0.068 * temperature # fitted from ITER Materials Design Limit Data, page 137 (IDM UID 222RLN)
    mat.electrical_conductivity = 5.96e7
    mat.unit_cost = 8.36 # source: https://www.focus-economics.com/commodities/base-metals/
    mat.critical_current_density = 18.5e6 # A/m^2
    mat.critical_magnetic_field = Inf
    return mat
end

function Material(::Type{Val{:dd_plasma}}; kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "dd_plasma"
    mat.type = [IMAS._plasma_]
    mat.density = 4e-5
    mat.unit_cost = 0.0
    return mat
end

function Material(::Type{Val{:dt_plasma}}; kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "dt_plasma"
    mat.type = [IMAS._plasma_]
    mat.density = 5e-5
    mat.unit_cost = 0.0
    return mat
end

function Material(::Type{Val{:flibe}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "flibe"
    mat.type = [IMAS._blanket_]
    mat.temperature = temperature
    mat.density = (temperature - 273.15) * -0.425 + 2245.5 # fitted from Vidrio et al, J. Chem. Eng. Data 2022, 67, 12
    mat.unit_cost = 43 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    return mat
end

function Material(::Type{Val{:graphite}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "graphite"
    mat.description = "Reactor grade carbon, graphite"
    mat.type = [IMAS._wall_]
    mat.density = 1.7e3
    mat.thermal_conductivity = 29815 * temperature^-1.5 + 0.704 # fitted from Paulatto et al, Phys. Rev. B, April 2013, Figure 14
    mat.electrical_conductivity = 3.3e2
    mat.unit_cost = 1.3 # source: https://businessanalytiq.com/procurementanalytics/index/graphite-price-index/
    return mat
end

function Material(::Type{Val{:lithium_lead}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "lithium_lead"
    mat.type = [IMAS._blanket_]
    mat.temperature = temperature
    mat.density = 10526.1 - 1.292 * temperature # fitted from  Khairulin et al, Int. Journal of Thermophysics 38(2)
    mat.unit_cost = 10 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
    return mat
end

function Material(
    ::Type{Val{:nb3sn}};
    coil_tech::Union{Missing,IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}=missing,
    Bext::Union{Real,Missing}=missing, kw...
)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "nb3sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 8.69e3
    mat.temperature = 4.2
    mat.unit_cost = 700 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 13

    if !ismissing(coil_tech)
        params_Nb3Sn = LTS_scaling(29330000, 28.45, 0.0739, 17.5, -0.7388, -0.5060, -0.0831, 0.8855, 2.169, 2.5, 0.0, 1.5, 2.2)
        Jcrit_SC, Bext_Bcrit_ratio = LTS_Jcrit(params_Nb3Sn, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature) # A/m^2
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

    return mat
end

function Material(
    ::Type{Val{:iter_nb3sn}};
    coil_tech::Union{Missing,IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}=missing,
    Bext::Union{Real,Missing}=missing, kw...
)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "iter_nb3sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 8.69e3
    mat.temperature = 4.2
    mat.unit_cost = 700 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 13

    if !ismissing(coil_tech)
        params_Nb3Sn = LTS_scaling(29330000, 28.45, 0.0739, 17.5, -0.7388, -0.5060, -0.0831, 0.8855, 2.169, 2.5, 0.0, 1.5, 2.2)
        Jcrit_SC, Bext_Bcrit_ratio = LTS_Jcrit(params_Nb3Sn, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature) # A/m^2
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

    return mat
end

function Material(
    ::Type{Val{:kdemo_nb3sn}};
    coil_tech::Union{Missing,IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}=missing,
    Bext::Union{Real,Missing}=missing, kw...
)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "kdemo_nb3sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 8.69e3
    mat.temperature = 4.2
    mat.unit_cost = 700 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 13

    if !ismissing(coil_tech)
        Jcrit_SC, Bext_Bcrit_ratio = KDEMO_Nb3Sn_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature)
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

    return mat
end

function Material(
    ::Type{Val{:nbti}};
    coil_tech::Union{Missing,IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}=missing,
    Bext::Union{Real,Missing}=missing, kw...
)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "nbti"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 5.7e3
    mat.unit_cost = 100 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 11 

    if !ismissing(coil_tech)
        params_NbTi = LTS_scaling(255.3e6, 14.67, -0.002e-2, 8.89, -0.0025, -0.0003, -0.0001, 1.341, 1.555, 2.274, 0.0, 1.758, 2.2) # Table 1, Journal of Phys: Conf. Series, 1559 (2020) 012063
        Jcrit_SC, Bext_Bcrit_ratio = LTS_Jcrit(params_NbTi, Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature) # A/m^2
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

    return mat
end

function Material(
    ::Type{Val{:rebco}};
    coil_tech::Union{Missing,IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology}=missing,
    Bext::Union{Real,Missing}=missing, kw...
)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "rebco"
    mat.type = [IMAS._tf_, IMAS._oh_]
    mat.density = 6.3e3
    mat.unit_cost = 7000

    if !ismissing(coil_tech)
        Jcrit_SC, Bext_Bcrit_ratio = ReBCO_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature) # A/m^2
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

    return mat
end

function Material(::Type{Val{:steel}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "steel"
    mat.type = [IMAS._cryostat_, IMAS._shield_]
    mat.density = 7.93e3
    mat.thermal_conductivity = 9.87 + 0.015 * temperature
    mat.electrical_conductivity = 1.45e6
    mat.unit_cost = 0.794 # source: https://www.focus-economics.com/commodities/base-metals/steel-usa/
    return mat
end

function Material(::Type{Val{:tungsten}}; temperature::Union{Real,Missing}=missing, kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "tungsten"
    mat.type = [IMAS._wall_]
    mat.density = 19.3e3
    mat.thermal_conductivity = 204.45 - 0.11986 * temperature + 3.6e-5 * temperature^2 # fitted from ITER Materials Design Limit Data, page 226 (IDM UID 222RLN)
    mat.electrical_conductivity = 1.87e7
    mat.unit_cost = 31.2 # source: https://almonty.com/tungsten/demand-pricing/
    return mat
end

function Material(::Type{Val{:vacuum}}; kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "vacuum"
    mat.type = [IMAS._gap_]
    mat.density = 0.0
    mat.unit_cost = 0
    return mat
end

function Material(::Type{Val{:water}}; kw...)
    test_allowed_keywords(kw)
    mat = Material()
    mat.name = "water"
    mat.type = [IMAS._vessel_]
    mat.density = 1.0e3
    mat.unit_cost = 0
    return mat
end
