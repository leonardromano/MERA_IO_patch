function my_loaddata(output::Int, datatype::Symbol;
                    path::String="./",
                    fname = "output_",
                    xrange::Array{<:Any,1}=[missing, missing],
                    yrange::Array{<:Any,1}=[missing, missing],
                    zrange::Array{<:Any,1}=[missing, missing],
                    center::Array{<:Any,1}=[0., 0., 0.],
                    range_unit::Symbol=:standard,
                    verbose::Bool=true,
                    myargs::ArgumentsType=ArgumentsType() )

        return my_loaddata(output, path=path,
                            fname=fname,
                            datatype=datatype,
                            xrange=xrange,
                            yrange=yrange,
                            zrange=zrange,
                            center=center,
                            range_unit=range_unit,
                            verbose=verbose,
                            myargs=myargs )
end

function my_loaddata(output::Int, path::String, datatype::Symbol;
                    fname = "output_",
                    xrange::Array{<:Any,1}=[missing, missing],
                    yrange::Array{<:Any,1}=[missing, missing],
                    zrange::Array{<:Any,1}=[missing, missing],
                    center::Array{<:Any,1}=[0., 0., 0.],
                    range_unit::Symbol=:standard,
                    verbose::Bool=true,
                    myargs::ArgumentsType=ArgumentsType() )

        return my_loaddata(output, path=path,
                            fname=fname,
                            datatype=datatype,
                            xrange=xrange,
                            yrange=yrange,
                            zrange=zrange,
                            center=center,
                            range_unit=range_unit,
                            verbose=verbose,
                            myargs=myargs )
end


function my_loaddata(output::Int, path::String;
                    fname = "output_",
                    datatype::Symbol,
                    xrange::Array{<:Any,1}=[missing, missing],
                    yrange::Array{<:Any,1}=[missing, missing],
                    zrange::Array{<:Any,1}=[missing, missing],
                    center::Array{<:Any,1}=[0., 0., 0.],
                    range_unit::Symbol=:standard,
                    verbose::Bool=true,
                    myargs::ArgumentsType=ArgumentsType() )

        return my_loaddata(output, path=path,
                            fname=fname,
                            datatype=datatype,
                            xrange=xrange,
                            yrange=yrange,
                            zrange=zrange,
                            center=center,
                            range_unit=range_unit,
                            verbose=verbose,
                            myargs=myargs )
end



function my_loaddata(output::Int; path::String="./",
                    fname = "output_",
                    datatype::Symbol,
                    xrange::Array{<:Any,1}=[missing, missing],
                    yrange::Array{<:Any,1}=[missing, missing],
                    zrange::Array{<:Any,1}=[missing, missing],
                    center::Array{<:Any,1}=[0., 0., 0.],
                    range_unit::Symbol=:standard,
                    verbose::Bool=true,
                    myargs::ArgumentsType=ArgumentsType() )

    # take values from myargs if given
    if !(myargs.xrange        === missing)        xrange = myargs.xrange end
    if !(myargs.yrange        === missing)        yrange = myargs.yrange end
    if !(myargs.zrange        === missing)        zrange = myargs.zrange end
    if !(myargs.center        === missing)        center = myargs.center end
    if !(myargs.range_unit    === missing)    range_unit = myargs.range_unit end
    if !(myargs.verbose       === missing)       verbose = myargs.verbose end

    # Leonard: "Mera."
    verbose = Mera.checkverbose(verbose)
    printtime("",verbose)

    filename = outputname(fname, output) * ".jld2"
    fpath    = checkpath(path, filename)

    if verbose
        println("Open Mera-file $filename:")
        println()
    end

    info = infodata(output, path=path, fname = fname,
                    datatype=datatype, verbose=false)
    #------------------
    # convert given ranges and print overview on screen
    # Leonard: "Mera."
    ranges = Mera.prepranges(info, range_unit, verbose, xrange, yrange, zrange, center)
    #------------------

    # load dataobject
    dlink = string(datatype) * "/data"
    dataobject = JLD2.load(fpath, dlink)

    # Leonard: everything related to dsets
    # get list with datasets
    dsets = Vector{String}(undef, 0)
    jldopen(fpath) do f
        if "datasets" in keys(f[string(datatype)].written_links)
            # Data is split up
            ddset = string(datatype) * "/datasets"
            indices = keys(f[ddset].written_links)
    
            for index in indices
                push!(dsets, ddset * "/" * index)
            end
        end
    end

    if !isempty(dsets)
        # merge data tables to obtain full dataset
        dataobject.data = JLD2.load(fpath, dsets[1])

        Ndset = length(dsets)
        for i in 2:Ndset
            dataobject.data = merge(dataobject.data, JLD2.load(fpath, dsets[i]))
        end
    end

    # filter selected data region
    dataobject = subregion(dataobject, :cuboid,
                     xrange=xrange,
                     yrange=yrange,
                     zrange=zrange,
                     center=center,
                     range_unit=range_unit,
                     verbose=false)

    # Leonard: "Mera."
    Mera.printtablememory(dataobject, verbose)

    return dataobject
end
