__precompile__(true)
module My_Mera_JLD2_Saving

# ==================================================================
# Save & Load RAMSES Snapshots with more than 2^32 entries.
#
# Leonard Romano, February 2023
# Max-Planck-Institute for Extraterrestrial Physics, Garching
# Ludwig-Maximillians-University, Munich
#
# Credits:
# The projection routine is strongly influenced by the Mera routines
# savedata & loaddata
# ==================================================================

# Julia libraries
using Mera
using JLD2, CodecZlib, CodecBzip2, Pkg, JuliaDB
using TimerOutputs

global verbose_mode = nothing
global showprogress_mode = nothing

export

    verbose_mode,
    showprogress_mode,

# basic calcs

    my_savedata,
    my_loaddata,
    my_convertdata

include("data_save.jl")
include("data_load.jl")
include("data_convert.jl")

end # module
