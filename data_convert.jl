# Leonard: only necessary because I call my_savedata
function my_convertdata(output::Int, datatypes::Array{Symbol, 1};
    path::String="./", fpath::String="./",
    fname = "output_",
    lmax::Union{Int, Missing}=missing,
    xrange::Array{<:Any,1}=[missing, missing],
    yrange::Array{<:Any,1}=[missing, missing],
    zrange::Array{<:Any,1}=[missing, missing],
    center::Array{<:Any,1}=[0., 0., 0.],
    range_unit::Symbol=:standard,
    smallr::Real=0.,
    smallc::Real=0.,
    verbose::Bool=true,
    show_progress::Bool=true,
    myargs::ArgumentsType=ArgumentsType() )


    return my_convertdata(output, datatypes=datatypes,
            path=path, fpath=fpath,
            fname = fname,
            lmax=lmax,
            xrange=xrange,
            yrange=yrange,
            zrange=zrange,
            center=center,
            range_unit=range_unit,
            smallr=smallr,
            smallc=smallc,
            verbose=verbose,
            show_progress=show_progress,
            myargs=myargs )
end

function my_convertdata(output::Int, datatypes::Symbol; path::String="./", fpath::String="./",
    fname = "output_",
    lmax::Union{Int, Missing}=missing,
    xrange::Array{<:Any,1}=[missing, missing],
    yrange::Array{<:Any,1}=[missing, missing],
    zrange::Array{<:Any,1}=[missing, missing],
    center::Array{<:Any,1}=[0., 0., 0.],
    range_unit::Symbol=:standard,
    smallr::Real=0.,
    smallc::Real=0.,
    verbose::Bool=true,
    show_progress::Bool=true,
    myargs::ArgumentsType=ArgumentsType() )


    return my_convertdata(output, datatypes=[datatypes],
            path=path, fpath=fpath,
            fname = fname,
            lmax=lmax,
            xrange=xrange,
            yrange=yrange,
            zrange=zrange,
            center=center,
            range_unit=range_unit,
            smallr=smallr,
            smallc=smallc,
            verbose=verbose,
            show_progress=show_progress,
            myargs=myargs )
end




function my_convertdata(output::Int; datatypes::Array{<:Any,1}=[missing], path::String="./", fpath::String="./",
    fname = "output_",
    lmax::Union{Int, Missing}=missing,
    xrange::Array{<:Any,1}=[missing, missing],
    yrange::Array{<:Any,1}=[missing, missing],
    zrange::Array{<:Any,1}=[missing, missing],
    center::Array{<:Any,1}=[0., 0., 0.],
    range_unit::Symbol=:standard,
    smallr::Real=0.,
    smallc::Real=0.,
    verbose::Bool=true,
    show_progress::Bool=true,
    myargs::ArgumentsType=ArgumentsType() )

    # take values from myargs if given
    if !(myargs.lmax          === missing)          lmax = myargs.lmax end
    if !(myargs.xrange        === missing)        xrange = myargs.xrange end
    if !(myargs.yrange        === missing)        yrange = myargs.yrange end
    if !(myargs.zrange        === missing)        zrange = myargs.zrange end
    if !(myargs.center        === missing)        center = myargs.center end
    if !(myargs.range_unit    === missing)    range_unit = myargs.range_unit end
    if !(myargs.verbose       === missing)       verbose = myargs.verbose end
    if !(myargs.show_progress === missing) show_progress = myargs.show_progress end

    verbose = Mera.checkverbose(verbose)
    show_progress = Mera.checkprogress(show_progress)
    printtime("",verbose)

    if length(datatypes) == 1 &&  datatypes[1] === missing || length(datatypes) == 0 || length(datatypes) == 1 &&  datatypes[1] == :all
        datatypes = [:hydro, :gravity, :particles, :clumps]
    else
        if !(:hydro in datatypes) && !(:gravity in datatypes) && !(:particles in datatypes) && !(:clumps in datatypes)
            error("unknown datatype(s) given...")
        end
    end

    verbose ? println("Requested datatypes: ", datatypes, "\n") : nothing

    memtot = 0.
    storage_tot = 0.
    overview = Dict()
    rw  = Dict()
    mem = Dict()
    lt = TimerOutput() # timer for loading data
    wt = TimerOutput() # timer for writing data

    info   = getinfo(output, path, verbose=false)
    lmax === missing ? lmax = info.levelmax : nothing
    si = storageoverview(info, verbose=false)
    #------------------
    # convert given ranges and print overview on screen
    ranges = Mera.prepranges(info, range_unit, verbose, xrange, yrange, zrange, center)
    #------------------

    # reading =============================
    verbose ? println("\nreading/writing lmax: ", lmax, " of ", info.levelmax) : nothing

    first_amrflag = true
    first_flag = true
    if info.hydro && :hydro in datatypes
        verbose ? println("- hydro") : nothing
        @timeit lt "hydro"  gas    = gethydro(info, lmax=lmax, smallr=smallr,
                smallc=smallc,
                xrange=xrange, yrange=yrange, zrange=zrange,
                center=center, range_unit=range_unit,
                verbose=false, show_progress=show_progress)
        memtot += Base.summarysize(gas)
        storage_tot += si[:hydro]
        if first_amrflag
            storage_tot += si[:amr]
            first_amrflag = false
        end

        # write
        first_flag, fmode = JLD2flag(first_flag)
        @timeit wt "hydro"  my_savedata(gas, path=fpath, fname=fname, fmode=fmode, verbose=false)

        # clear mem
        gas = 0.
    end

    if info.gravity && :gravity in datatypes
        verbose ? println("- gravity") : nothing
        @timeit lt "gravity"  grav    = getgravity(info, lmax=lmax,
                xrange=xrange, yrange=yrange, zrange=zrange,
                center=center, range_unit=range_unit,
                verbose=false, show_progress=show_progress)
        memtot += Base.summarysize(grav)
        storage_tot += si[:gravity]
        if first_amrflag
            storage_tot += si[:amr]
            first_amrflag = false
        end

        # write
        first_flag, fmode = JLD2flag(first_flag)
        @timeit wt "gravity"  my_savedata(grav, path=fpath, fname=fname, fmode=fmode, verbose=false)

        # clear mem
        grav = 0.
    end

    if info.particles && :particles in datatypes
        verbose ? println("- particles") : nothing
        @timeit lt "particles"  part    = getparticles(info,
                xrange=xrange, yrange=yrange, zrange=zrange,
                center=center, range_unit=range_unit,
                verbose=false, show_progress=show_progress)
        memtot += Base.summarysize(part)
        storage_tot += si[:particle]
        if first_amrflag
            storage_tot += si[:amr]
            first_amrflag = false
        end

        # write
        first_flag, fmode = JLD2flag(first_flag)
        @timeit wt "particles"  my_savedata(part, path=fpath, fname=fname, fmode=fmode, verbose=false)

        # clear mem
        part = 0.
    end

    if info.clumps && :clumps in datatypes
        verbose ? println("- clumps") : nothing
        @timeit lt "clumps"  clumps    = getclumps(info,
                xrange=xrange, yrange=yrange, zrange=zrange,
                center=center, range_unit=range_unit,
                verbose=false)
        memtot += Base.summarysize(clumps)
        storage_tot += si[:clump]

        # write
        first_flag, fmode = JLD2flag(first_flag)
        @timeit wt "clumps"  my_savedata(clumps, path=fpath, fname=fname, fmode=fmode, verbose=false)

        # clear mem
        clumps = 0.
    end

    icpu= info.output
    filename = outputname(fname, icpu) * ".jld2"
    fullpath    = checkpath(fpath, filename)
    s = filesize(fullpath)
    foldersize = si[:folder]
    mem["folder"] = [foldersize, "Bytes"]
    mem["selected"] = [storage_tot, "Bytes"]
    mem["used"] = [memtot, "Bytes"]
    mem["ondisc"] = [s, "Bytes"]
    if verbose
        fvalue, funit = humanize(Float64(foldersize), 3, "memory")
        ovalue, ounit = humanize(Float64(storage_tot), 3, "memory")
        mvalue, munit = humanize(Float64(memtot), 3, "memory")
        svalue, sunit = humanize(Float64(s), 3, "memory")
        println()
        println("Total datasize:")
        println("- total folder: ", fvalue, " ", funit)
        println("- selected: ", ovalue, " ", ounit)
        println("- used: ", mvalue, " ", munit)
        println("- new on disc: ", svalue, " ", sunit)
    end
    rw["reading"] = lt
    rw["writing"] = wt
    overview["TimerOutputs"] = rw
    overview["viewdata"] = viewdata(output, path=fpath, fname=fname, verbose=false)
    overview["size"] = mem

    jld2mode = "a+" # append
    jldopen(fullpath, jld2mode) do f
        f["convertstat"] = overview
    end

    return overview
end


function JLD2flag(first_flag::Bool)
    if first_flag
        fmode=:write
        first_flag=false
    else
        fmode=:append
    end
    return first_flag, fmode
end
