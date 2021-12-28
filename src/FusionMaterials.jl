__precompile__()

module FusionMaterials

using JSON

const cache = Dict()

"""
    available_materials_groups()

Return list of available materials groups
"""
function available_materials_groups()
    [replace(filename, ".json" => "") for filename in readdir(joinpath(dirname(dirname(@__FILE__)), "data")) if endswith(filename, ".json")]
end

"""
    available_materials(by_group::Bool=true)

Return available materials sorted by materials' group or not
"""
function available_materials(by_group::Bool = true)
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
function available_materials(group_name::String)
    return collect(keys(material_group(group_name)))
end

"""
    material_group(group_name::String)

Return dictionary with materials
"""
function material_group(group_name::String)
    filename = joinpath(dirname(dirname(@__FILE__)), "data", "$group_name.json")
    if !(filename in keys(cache))
        materials = JSON.parsefile(filename)
        cache[filename] = materials
    end
    materials = cache[filename]
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
    error("Material $material_name not found")
end

"""
    material(material_group::String, material_name::String)

Return material given its group and name
"""
function material(material_group::String, material_name::String)
    return material_group(material_group)[material_name]
end

export available_materials_groups, available_materials, material

end # module
