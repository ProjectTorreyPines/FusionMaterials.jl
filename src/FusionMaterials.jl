module FusionMaterials

import IMAS

include("materials.jl")

include("jcrit.jl")

include("materials_utils.jl")

export Material

const document = Dict()
document[Symbol(@__MODULE__)] = [name for name in Base.names(@__MODULE__, all=false, imported=false) if name != Symbol(@__MODULE__)]

end # module
