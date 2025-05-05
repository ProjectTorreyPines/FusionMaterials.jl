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

"""
    new_compound_layer(layer::IMAS.build__layer, composition_dict::AbstractDict{String, <:Real})

Takes a dictionary containing material names and compositions and assigns them to a specified layer 
"""

function new_compound_layer(layer::IMAS.build__layer, composition_dict::AbstractDict{String, <:Real})
    @assert sum([composition_dict[key] for key in keys(composition_dict)]) ≈ 1 "Sum of material fractions must be 1"

    resize!(layer.material, length(composition_dict))

    for (i, key) in enumerate(keys(composition_dict))
        layer.material[i].name = key
        layer.material[i].composition = composition_dict[key]
    end
end

"""
    compound_material_property(layer::IMAS.build__layer, mat_property::Symbol; temperature::Float64, Bext::Float64=missing)

Returns the composite material property for a specified composition of multiple materials as a simple linear combination 
"""

function compound_material_property(tech::Union{IMAS.build__layer, IMAS.build__oh__technology,IMAS.build__pf_active__technology,IMAS.build__tf__technology}, mat_property::Symbol; temperature::Union{Missing,Float64}=missing, Bext::Union{Missing,Float64}=missing)
    if length(tech.material) == 1 
        if ismissing(getfield(FusionMaterials.Material(tech.material[1].name), mat_property))
            error("$mat_property is not defined for $(tech.material[1].name)")
        else 
            composite_property = getproperty(FusionMaterials.Material(tech.material[1].name), mat_property)(;temperature = temperature, Bext = Bext)
        end
    else 
        composite_property = 0
        for i in (1:length(tech.material))
            if ismissing(getfield(FusionMaterials.Material(tech.material[i].name), mat_property))
                continue
            else
                try 
                    composite_property += getproperty(FusionMaterials.Material(tech.material[i].name), mat_property)(;temperature = temperature, Bext = Bext) * tech.material[i].composition
                catch(e)
                    composite_property += getproperty(FusionMaterials.Material(tech.material[i].name), mat_property)(;temperature = temperature) * tech.material[i].composition
                end
            end
        end
    end

    return composite_property

end

"""
    primary_coil_material(coil_tech::Union{IMAS.build__tf__technology, IMAS.build__oh__technology, IMAS.build__pf_active__technology})

Returns the primary conducting/superconducting material from a compound build layer describing a coil 
"""

function primary_coil_material(coil_tech::Union{IMAS.build__tf__technology, IMAS.build__oh__technology, IMAS.build__pf_active__technology})
    all_mats = [coil_tech.material[i].name for i in eachindex(coil_tech.material)]
    mats = Set(all_mats)
    mats = setdiff(mats, Set(["copper", "vacuum", "steel"]))
    if length(mats) == 1
        return collect(mats)[1]
    elseif isempty(mats)
        return "copper"
    else
        error("Cannot determine primary material from: $(all_mats)")
    end
end

function fraction_conductor(coil_tech::Union{IMAS.build__pf_active__technology,IMAS.build__oh__technology,IMAS.build__tf__technology})
    frac = 1.0 - coil_tech.fraction_steel - coil_tech.fraction_void # fraction of coil that is a conductor
    @assert frac > 0.0 "coil technology has no room for conductor"
    if primary_coil_material(coil_tech) == "copper"
        return frac
    else
        return frac * coil_tech.ratio_SC_to_copper / (1.0 + coil_tech.ratio_SC_to_copper) # fraction of coil that is Nb3Sn superconductor
    end
end

# Dispatch on symbol and string

function Material(name::Symbol, args...; kw...)
    return Material(Val{name}, args...; kw...)
end

function Material(name::AbstractString, args...; kw...)
    return Material(Val{Symbol(name)}, args...; kw...)
end