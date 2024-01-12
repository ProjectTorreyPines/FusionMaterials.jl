Base.@kwdef mutable struct Material
	name::Union{String, Missing} = missing
    type::Union{Vector{IMAS.BuildLayerType}, Missing} = missing
	density::Union{Real, Missing} = missing # g/cm^3
	temperature::Union{Real, Missing} = missing # C
	critical_current_density::Union{Real, Missing} = missing
	critical_magnetic_field::Union{Real, Missing} = missing # T/T
	unit_cost::Union{Real, Missing} = missing # $/kg
end


function Material(::Type{Val{:Aluminum}})
	mat = Material()
	mat.name = "Aluminum"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 2.7
	mat.unit_cost = 2.16 # source: https://www.focus-economics.com/commodities/base-metals/
	return mat
end

function Material(::Type{Val{:Copper}})
	mat = Material()
	mat.name = "Copper"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 8.96
	mat.unit_cost = 8.36 # source: https://www.focus-economics.com/commodities/base-metals/
	mat.critical_current_density = 18.5e6 # A/m^2
	mat.critical_magnetic_field = Inf
	return mat
end

function Material(::Type{Val{:DD_plasma}})
	mat = Material()
	mat.name = "DD_plasma"
    mat.density = 0.00000004
    mat.unit_cost = 0.0
	return mat
end

function Material(::Type{Val{:DT_plasma}})
	mat = Material()
	mat.name = "DT_plasma"
    mat.density = 0.00000005
    mat.unit_cost = 0.0
	return mat
end

function Material(::Type{Val{:FLiBe}}; temperature::Real = 500.0)
	mat = Material()
	mat.name = "FLiBe"
    mat.type = [IMAS._blanket_]
	mat.temperature = temperature
	mat.density = 2.214 - 4.2e-4 * temperature
	mat.unit_cost = 43 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
	return mat
end

function Material(::Type{Val{:Graphite}};)
	mat = Material()
	mat.name = "Graphite"
    mat.type = [IMAS._wall_]
	mat.density = 1.7
	mat.unit_cost = 1.3 # source: https://businessanalytiq.com/procurementanalytics/index/graphite-price-index/
	return mat
end

function Material(::Type{Val{:Lithium_Lead}}; temperature::Real = 500.0)
	mat = Material()
	mat.name = "Lithium-Lead"
    mat.type = [IMAS._blanket_]
	mat.temperature = temperature
	mat.density = 99.90 * (0.1 - 16.8e-6 * temperature) # density equation valid in the range 240-350 C, need to fix this
	mat.unit_cost = 10 # source: https://fti.neep.wisc.edu/fti.neep.wisc.edu/presentations/mes_zpinch_tofe06.pdf, slide 20
	return mat
end

# fix Bext placeholder value 
function Material(::Type{Val{:Nb3Sn}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Real = 1.0)
	mat = Material()
	mat.name = "Nb3Sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 8.69
	mat.temperature = 4.2 # fix this bc now it's K in some places and C in others 
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

function Material(::Type{Val{:ITER_Nb3Sn}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Real = 1.0)
	mat = Material()
	mat.name = "ITER_Nb3Sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 8.69
	mat.temperature = 4.2 # fix this bc now it's K in some places and C in others 
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

function Material(::Type{Val{:KDEMO_Nb3Sn}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Real = 1.0)
	mat = Material()
	mat.name = "KDEMO_Nb3Sn"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 8.69
	mat.temperature = 4.2 # fix this bc now it's K in some places and C in others 
	mat.unit_cost = 700 # source: https://uspas.fnal.gov/materials/18MSU/U4-2018.pdf, slide 13

    if !ismissing(coil_tech)
        Jcrit_SC, Bext_Bcrit_ratio = KDEMO_Nb3Sn_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature)
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

	return mat
end

function Material(::Type{Val{:NbTi}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Real = 1.0)
	mat = Material()
	mat.name = "NbTi"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 5.7
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

function Material(::Type{Val{:ReBCO}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Real = 1.0)
	mat = Material()
	mat.name = "ReBCO"
    mat.type = [IMAS._tf_, IMAS._oh_]
	mat.density = 6.3
	mat.unit_cost = 7000

    if !ismissing(coil_tech)
        Jcrit_SC, Bext_Bcrit_ratio = ReBCO_Jcrit(Bext, coil_tech.thermal_strain + coil_tech.JxB_strain, coil_tech.temperature) # A/m^2
        fc = fraction_conductor(coil_tech)
        mat.critical_current_density = Jcrit_SC * fc
        mat.critical_magnetic_field = Bext / Bext_Bcrit_ratio
    end

	return mat
end

function Material(::Type{Val{:Steel}})
	mat = Material()
	mat.name = "Steel"
    mat.type = [IMAS._vessel_]
	mat.density = 7.93
	mat.unit_cost = 0.794 # source: https://www.focus-economics.com/commodities/base-metals/steel-usa/
	return mat
end

function Material(::Type{Val{:Tungsten}})
	mat = Material()
	mat.name = "Tungsten"
    mat.type = [IMAS._wall_]
	mat.density = 19.3
	mat.unit_cost = 31.2 # source: https://almonty.com/tungsten/demand-pricing/
	return mat
end

function Material(::Type{Val{:Vacuum}})
	mat = Material()
	mat.name = "Vacuum"
    mat.type = [IMAS._gap_]
	mat.density = 0.0
	mat.unit_cost = 0
	return mat
end

function Material(::Type{Val{:Water}})
	mat = Material()
	mat.name = "Water"
	mat.density = 1.0
	mat.unit_cost = 0
	return mat
end

#############
# Utilities #
#############

function Material(name_as_string::String)
	name_as_string = replace(name_as_string, "-" => "_")
	return Material(Symbol(name_as_string))
end

function is_supported_material(mat::Symbol, layer_type::IMAS.BuildLayerType)
    all_materials = [:Aluminum, :Copper, :FLiBe, :Graphite, :Lithium_Lead, :Nb3Sn, :ITER_Nb3Sn, :KDEMO_Nb3Sn, :NbTi, :ReBCO, :Steel, :Tungsten, :Vacuum]
    
    if mat ∉ all_materials
        error("$mat is not a valid material. Supported materials are $(join(all_materials, ", "))" )
    end

    supported_materials = []
        
       for mats in all_materials
            if layer_type ∈ FusionMaterials.Material(mats).type
                push!(supported_materials, Symbol(FusionMaterials.Material(mats).name))
            end
        end
            
        if layer_type ∉ FusionMaterials.Material(mat).type 
            pretty_layer_type = replace("$layer_type", "_" => "")
            error("$mat is not a valid $pretty_layer_type material. Valid material options for $pretty_layer_type are $(join(supported_materials, ", "))")
        end
end 

function supported_coil_techs()
    supported_coil_materials::Vector{Symbol} = []
    all_materials = [:Aluminum, :Copper, :FLiBe, :Graphite, :Lithium_Lead, :Nb3Sn, :ITER_Nb3Sn, :KDEMO_Nb3Sn, :NbTi, :ReBCO, :Steel, :Tungsten, :Vacuum]

    for mats in all_materials
        if IMAS._tf_ ∈ FusionMaterials.Material(mats).type || IMAS._oh_ ∈ FusionMaterials.Material(mats).type
            push!(supported_coil_materials, Symbol(FusionMaterials.Material(mats).name))
        end
    end

    return supported_coil_materials
end

# Dispatch on symbol

function Material(name::Symbol, args...; kw...)
	return Material(Val{name}, args...; kw...)
end

