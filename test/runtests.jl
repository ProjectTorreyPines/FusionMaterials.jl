using Test
using FusionMaterials
import FusionMaterials.IMAS

@testset "all_materials" begin
    for material_name in sort(FusionMaterials.all_materials())
        println(material_name)
        mat = Material(material_name)
        if !ismissing(mat.density)
            mat.density(; temperature=293.15)
        end
        if !ismissing(mat.electrical_conductivity)
            mat.electrical_conductivity(; temperature=293.15)
        end
        if !ismissing(mat.electrical_conductivity)
            mat.electrical_conductivity(; temperature=293.15)
        end
        if !ismissing(mat.critical_current_density)
            coil_tech = IMAS.coil_technology(IMAS.build__tf__technology(), material_name, :tf)
            mat.critical_current_density(; coil_tech, temperature=4.2, Bext=1.0)
        end
        if !ismissing(mat.critical_magnetic_field)
            coil_tech = IMAS.coil_technology(IMAS.build__tf__technology(), material_name, :tf)
            mat.critical_magnetic_field(; coil_tech, temperature=4.2, Bext=1.0)
        end
    end
end

@testset "material_from_coil_tech" begin
    coil_tech = IMAS.coil_technology(IMAS.build__tf__technology(), :nb3sn, :tf)
    mat = Material(coil_tech)
    mat.critical_current_density(;temperature=4.2, Bext=1.0)
end

@testset "density_vs_temperature" begin
    temperatures = 400.0:50.0:800.0
    mat = FusionMaterials.Material(:lithium_lead)
    dens = [mat.density(; temperature) for temperature in temperatures]
end

@testset "is_supported_material" begin
    @test_throws Exception FusionMaterials.is_supported_material(:lithium_lead, IMAS._tf_)
    @test FusionMaterials.is_supported_material(:lithium_lead, IMAS._tf_; raise_error=false) == false
    @test FusionMaterials.is_supported_material(:rebco, IMAS._tf_)
end

@testset "material_type" begin
    @test FusionMaterials.Material(:rebco).type == [IMAS._tf_, IMAS._oh_]
    @test FusionMaterials.Material(:tungsten).type == [IMAS._wall_]
end