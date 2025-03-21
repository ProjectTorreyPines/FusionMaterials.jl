#############
# Utilities #
#############

"""
    all_materials()

Collects and returns a list of all unique materials supported by the `Material` function, extracted from its methods' signatures.
"""
function all_materials()
    all_materials = Symbol[]
    for m in methods(Material)
        try
            if m.sig.parameters[2] isa DataType && m.sig.parameters[2].parameters[1].name.name == :Val
                material = m.sig.parameters[2].parameters[1].parameters[1]
                push!(all_materials, material)
            end
        catch
            continue
        end
    end
    return all_materials
end

"""
    ALL_MATERIALS

A constant that caches the result of calling `all_materials()`.
This computation is performed only once when the module or script is loaded, so subsequent accesses simply retrieve the precomputed list.
It returns a list of all unique materials supported by the `Material` function.
"""
const ALL_MATERIALS = all_materials()

"""
    test_allowed_keywords(kw)

Verifies if the keyword arguments provided (`kw`) are among the allowed environment keywords. Throws an assertion error if any keyword is not allowed.
"""
function test_allowed_keywords(kw)
    allowed_environment_keywords = [:coil_tech, :temperature, :Bext]
    @assert all(k -> k in allowed_environment_keywords, keys(kw)) "only $allowed_environment_keywords are allowed as keyword arguments to Material function"
end

"""
    is_supported_material(mat::Symbol, layer_type::IMAS.BuildLayerType; raise_error::Bool=true)

Determines if a given material (`mat`) is supported for a specific layer type (`layer_type`).
Optionally raises an error (`raise_error`) if the material is not supported.
"""
function is_supported_material(mat::Symbol, layer_type::IMAS.BuildLayerType; raise_error::Bool=true)

    if mat ∉ all_materials()
        if raise_error
            error("$mat is not a valid material. Supported materials are $(join(all_materials(), ", "))")
        else
            return false
        end
    end

    supported_materials = Symbol[]

    for mats in all_materials()
        if layer_type ∈ FusionMaterials.Material(mats).type
            push!(supported_materials, Symbol(FusionMaterials.Material(mats).name))
        end
    end

    if layer_type ∉ FusionMaterials.Material(mat).type
        pretty_layer_type = replace("$layer_type", "_" => "")
        if raise_error
            error("$mat is not a valid $pretty_layer_type material. Valid material options for $pretty_layer_type are $(join(supported_materials, ", "))")
        else
            return false
        end
    end

    return true
end

"""
    supported_coil_techs()

Returns a list of materials supported for use in coil technologies
"""
function supported_coil_techs()
    supported_coil_materials = Symbol[]

    for mats in all_materials()
        if IMAS._tf_ ∈ FusionMaterials.Material(mats).type || IMAS._oh_ ∈ FusionMaterials.Material(mats).type
            push!(supported_coil_materials, Symbol(FusionMaterials.Material(mats).name))
        end
    end

    return supported_coil_materials
end

"""
    supported_material_list(layer_type::IMAS.BuildLayerType)

Generates a list of materials supported for a given IMAS layer type (`layer_type`)
"""
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