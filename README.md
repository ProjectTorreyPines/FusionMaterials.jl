# FusionMaterials.jl

This is a pure-Julia interface to the data from the neutronics_material_maker Python package
https://github.com/fusion-energy/neutronics_material_maker

At this point FusionMaterials.jl is really only meant to be used to pick materials
that are available in neutronics_material_maker

Note that under the hood neutronics_material_maker makes use of the coolprop package,
which we could also call as described here http://www.coolprop.org/coolprop/wrappers/Julia/index.html
