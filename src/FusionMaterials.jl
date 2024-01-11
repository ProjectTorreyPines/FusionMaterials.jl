module FusionMaterials

using JSON
using IMAS

include("materials.jl")
include("jcrit.jl")

const cache = Dict()

"""
    available_materials_groups()

Return list of available materials groups
"""
function available_materials_groups()
    original = [replace(filename, ".json" => "") for filename in readdir(joinpath(dirname(@__DIR__), "data")) if endswith(filename, ".json")]
    return sort(unique(vcat(original..., collect(keys(custom))...)))
end

"""
    available_materials(;by_group::Bool=true)

Return available materials sorted by materials' group or not
"""
function available_materials(; by_group::Bool=true)
    materials_names_dict = Dict()
    materials_names_list = []
    for mg in available_materials_groups()
        materials_names_dict[mg] = available_materials(mg)
        append!(materials_names_list, materials_names_dict[mg])
    end
    if by_group
        return materials_names_dict
    else
        return materials_names_list
    end
end

"""
    available_materials(group_name::String)

Return available materials within a group
"""
function available_materials(group_name::String)::Vector{String}
    return collect(keys(material_group(group_name)))
end

"""
    available_materials(group_name::AbstractVector(String))

Return available materials within several groups
"""
function available_materials(group_names::Vector{String})::Vector{String}
    return vcat((collect(keys(material_group(group_name))) for group_name in group_names)...)
end

function available_materials(regex::Regex)::Vector{String}
    materials = available_materials(; by_group=false)
    return [material for material in materials if match(regex, material) !== nothing]
end

"""
    material_group(group_name::String)

Return dictionary with materials
"""
function material_group(group_name::String)
    if group_name in keys(custom)
        return custom[group_name]
    elseif !(group_name in keys(cache))
        filename = joinpath(dirname(@__DIR__), "data", "$group_name.json")
        materials = JSON.parsefile(filename)
        cache[group_name] = materials
    end
    return materials = cache[group_name]
end

"""
    material(material_name::String)

Return material given its name
"""
function material(material_name::String)
    for mg in available_materials_groups()
        materials = material_group(mg)
        if material_name in keys(materials)
            return materials[material_name]
        end
    end
    return error("Material $material_name not found")
end

"""
    material(material_group::String, material_name::String)

Return material given its group and name
"""
function material(material_group::String, material_name::String)
    return material_group(material_group)[material_name]
end

"""
    detect_duplicates()
"""
function detect_duplicates()
    duplicates = Dict()
    for mg in available_materials_groups()
        if mg in keys(custom)
            continue
        end
        materials = material_group(mg)
        for mat in keys(materials)
            if mat ∉ keys(duplicates)
                duplicates[mat] = [mg]
            else
                push!(duplicates[mat], mg)
            end
        end
    end
    for mat in keys(duplicates)
        if length(duplicates[mat]) == 1
            pop!(duplicates, mat)
        end
    end
    return duplicates
end

const custom = Dict()

custom["blanket_materials"] = Dict()
for mat in ("lithium-lead", "FLiBe")
    custom["blanket_materials"][mat] = material(mat)
end

custom["wall_materials"] = Dict()
for mat in ("Steel, Stainless 316", "Tungsten", "Carbon, Graphite (reactor grade)")
    custom["wall_materials"][mat] = material(mat)
end

custom["shield_materials"] = Dict()
for mat in ("Steel, Stainless 316", "Tungsten")
    custom["shield_materials"][mat] = material(mat)
end

empty!(cache)

export available_materials_groups, available_materials, material

end # module
