#############
# Utilities #
#############

const all_materials = [:Aluminum, :Copper, :DD_plasma, :DT_plasma, :FLiBe, :Graphite, :Lithium_Lead, :Nb3Sn, :ITER_Nb3Sn, :KDEMO_Nb3Sn, :NbTi, :ReBCO, :Steel, :Tungsten, :Vacuum, :Water]

function Material(name_as_string::String)
	name_as_string = replace(name_as_string, "-" => "_")
	return Material(Symbol(name_as_string))
end

function is_supported_material(mat::Symbol, layer_type::IMAS.BuildLayerType)
    
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