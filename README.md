# FusionMaterials.jl

This is a pure-Julia interface to the data from the neutronics_material_maker Python package
https://github.com/fusion-energy/neutronics_material_maker

## Add a new material 

Properties of each material can be accessed by calling the `Material()` function with the material name **as a symbol** passed as the function argument. 

To add a new material, first add a function to `src/materials.jl` called Material with the function argument being your material's name. In the body of the function, assign the material's name (as a string, all lowercase, and with any spaces filled by underscores), type (as a list containing each possible IMAS BuildLayerType the material could be assigned to), density (in `kg/m^3`) and unit cost (in US dollars per kilogram). Include a comment providing a link to the source from which the unit cost was taken. 

Below is an example of a complete Material function for a non-superconductor material (more about superconductor materials below): 

```julia 
function Material(::Type{Val{:graphite}};)
	mat = Material()
	mat.name = "graphite" # string with no spaces
	mat.type = [IMAS._wall_] # list of allowable layer types for this material
	mat.density = 1.7e3 # in kg/m^3
	mat.unit_cost = 1.3 # in US$/kg, include source as a comment # source: https://businessanalytiq.com/procurementanalytics/index/graphite-price-index/
	return mat
end
```

If the material is a superconductor that is meant to be assigned to magnet-type layers, additional characteristics need to be defined. First, add the relevant critical current density scaling for the chosen superconductor material as a function in `FusionMaterials/src/jcrit.jl`. Then, assign the technology parameters for the material (temperature, steel fraction, void fraction, and ratio of superconductor to copper) to their respective fields in coil_tech within the coil_technology function in `FUSE/src/technology.jl`. Finally, call the critical current density scaling function within the newly written Material function in `materials.jl` and assign the output critical current density and critical magnetic field to the material object. The coil_tech object should be passed as an argument to the Material function, along with the external B field, and used to calculate the critical current density and critical magnetic field. 

Below is an example of a complete superconductor Material function: 

```julia 
function Material(::Type{Val{:rebco}}; coil_tech::Union{Missing, IMAS.build__pf_active__technology, IMAS.build__oh__technology, IMAS.build__tf__technology} = missing, Bext::Union{Real, Missing} = missing)
	mat = Material()
	mat.name = "rebco"
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
```

The function `ReBCO_Jcrit` is the critical current density function for this material. 

You can then access the parameters of your material by calling the function you've created. For example, access the material's density anywhere in FUSE by calling: 

```julia
my_mat_density = Material(:my_mat).density
```

## Online documentation
For more details, see the [online documentation](https://projecttorreypines.github.io/FusionMaterials.jl/dev).

![Docs](https://github.com/ProjectTorreyPines/FusionMaterials.jl/actions/workflows/make_docs.yml/badge.svg)