#############
# Utilities #
#############

function all_materials()
    all_materials = Symbol[]
    for m in methods(Material)
        if length(m.sig.parameters) == 2
            if m.sig.parameters[2] isa DataType
                material = m.sig.parameters[2].parameters[1].parameters[1]
                push!(all_materials, material)
            end
        end
    end
    return all_materials
end

function test_allowed_keywords(kw)
    allowed_environment_keywords = [:coil_tech, :temperature, :Bext]
    @assert all(k -> k in allowed_environment_keywords, keys(kw)) "only $allowed_environment_keywords are allowed as keyword arguments to Material function"
end

function is_supported_material(mat::Symbol, layer_type::IMAS.BuildLayerType)

    if mat ∉ all_materials()
        error("$mat is not a valid material. Supported materials are $(join(all_materials(), ", "))")
    end

    supported_materials = Symbol[]

    for mats in all_materials()
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
    supported_coil_materials = Symbol[]

    for mats in all_materials()
        if IMAS._tf_ ∈ FusionMaterials.Material(mats).type || IMAS._oh_ ∈ FusionMaterials.Material(mats).type
            push!(supported_coil_materials, Symbol(FusionMaterials.Material(mats).name))
        end
    end

    return supported_coil_materials
end

function supported_material_list(layer_type::IMAS.BuildLayerType)
    supported_material_list = Symbol[]

    for mats in all_materials()
        if layer_type ∈ FusionMaterials.Material(mats).type
            push!(supported_material_list, Symbol(FusionMaterials.Material(mats).name))
        end
    end

    return supported_material_list
end

# Dispatch on symbol and string

function Material(name::Symbol, args...; kw...)
    return Material(Val{name}, args...; kw...)
end

function Material(name::AbstractString, args...; kw...)
    return Material(Val{Symbol(name)}, args...; kw...)
end