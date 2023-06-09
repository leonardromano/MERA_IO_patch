function my_savedata( dataobject::DataSetType, fmode::Symbol;
    path::String="./",
    fname = "output_",
    dataformat::Symbol=:JLD2,
    compress::Any=nothing,
    comments::Any=nothing,
    merafile_version::Float64=1.,
    verbose::Bool=true)

    return my_savedata( dataobject,
                        path=path,
                        fname=fname,
                        fmode=fmode,
                        dataformat=dataformat,
                        compress=compress,
                        comments=comments,
                        merafile_version=merafile_version,
                        verbose=verbose)
end

function my_savedata( dataobject::DataSetType, path::String, fmode::Symbol;
    fname = "output_",
    dataformat::Symbol=:JLD2,
    compress::Any=nothing,
    comments::Any=nothing,
    merafile_version::Float64=1.,
    verbose::Bool=true)

    return my_savedata( dataobject,
                        path=path,
                        fname=fname,
                        fmode=fmode,
                        dataformat=dataformat,
                        compress=compress,
                        comments=comments,
                        merafile_version=merafile_version,
                        verbose=verbose)
end

function my_savedata( dataobject::DataSetType, path::String;
    fname = "output_",
    fmode::Any=nothing,
    dataformat::Symbol=:JLD2,
    compress::Any=nothing,
    comments::Any=nothing,
    merafile_version::Float64=1.,
    verbose::Bool=true)

    return my_savedata( dataobject,
                        path=path,
                        fname=fname,
                        fmode=fmode,
                        dataformat=dataformat,
                        compress=compress,
                        comments=comments,
                        merafile_version=merafile_version,
                        verbose=verbose)
end

function my_savedata( dataobject::DataSetType;
    path::String="./",
    fname = "output_",
    fmode::Any=nothing,
    dataformat::Symbol=:JLD2,
    compress::Any=nothing,
    comments::Any=nothing,
    merafile_version::Float64=1.,
    verbose::Bool=true)

    # Leonard: "Mera."
    verbose = Mera.checkverbose(verbose)
    printtime("",verbose)

    datatype, use_descriptor, descriptor_names = check_datasource(dataobject)

    icpu= dataobject.info.output
    filename = outputname(fname, icpu) * ".jld2"
    fpath    = checkpath(path, filename)
    fexist, wdata, jld2mode = check_file_mode(fmode, datatype, path, filename, verbose)
    ctype = check_compression(compress, wdata)
    column_names = propertynames(dataobject.data.columns)

    if verbose
        println("Directory: ", dataobject.info.path )
        println("-----------------------------------")
        println("merafile_version: ", merafile_version, "  -  Simulation code: ", dataobject.info.simcode)
        println("-----------------------------------")
        println("DataType: ", datatype, "  -  Data variables: ", column_names)
        if use_descriptor
            println("Descriptor: ", descriptor_names)
        end
        println("-----------------------------------")
        println("I/O mode: ", fmode, "  -  Compression: ", ctype)
        println("-----------------------------------")
    end

    # Get names of fields & keys
    fields = column_names
    pkey   = fields[dataobject.data.pkey]

    # Leonard: Computing Nsplit
    # Get number of entries in database
    Nrows    = length(dataobject.data)
    Ncolumns = length(fields)
    Nentry   = Nrows * Ncolumns

    # Maximum number of entries per field is 2^32, so determine number of splits
    Nsplit = ceil(Int, Nentry / 2^32)

    if wdata
        jldopen(fpath, jld2mode; compress = ctype) do f
            dt = string(datatype)

            df = "/information/"

            f[dt * df * "compression"] = ctype
            f[dt * df * "comments"] = comments

            f[dt * df * "versions/merafile_version"] = merafile_version
            f[dt * df * "versions/JLD2compatible_versions"] = JLD2.COMPATIBLE_VERSIONS
            
            # check dependencies
            pkg = Pkg.dependencies()
            check_pkg = ["Mera","JLD2", "CodecZlib", "CodecBzip2"]
            for i  in keys(pkg)
                ipgk = pkg[i]
                if ipgk.name in check_pkg
                    if ipgk.is_tracking_repo
                        f[dt * df * "versions/" * ipgk.name] = [ipgk.version, ipgk.git_source]
                    else
                        f[dt * df * "versions/" * ipgk.name] = [ipgk.version]
                    end

                    if verbose
                        if ipgk.is_tracking_repo
                            println(ipgk.name, "  ", ipgk.version, "   ", ipgk.git_source)
                        else
                            println(ipgk.name, "  ", ipgk.version)
                        end
                    end
                end
            end

            f[dt * df * "storage"] = storageoverview(dataobject.info, verbose=false)
            f[dt * df * "memory"]  = usedmemory(dataobject, false)

            # Leonard: if ... else ... end
            if Nsplit == 1
                f[dt * "/data"] = dataobject
            else
                # Split up database into smaller chunks
                k1 = 1
            
                for i in 1:Nsplit
                    # Last Index
                    k2        = floor(Int, Nrows * (i/Nsplit))
                    f[dt * "/datasets/$(i)"] = dataobject.data[k1:k2]

                    # First Index
                    k1 = k2+1
                end

                # keep metadata with empty DataTable
                metadata = typeof(dataobject)()
                for property in propertynames(dataobject)
                    if property != :data
                        setproperty!(metadata, property, getproperty(dataobject, property))
                    else
                        metadata.data = table([[] for field in fields]..., names=fields, pkey=pkey, presorted=false)
                    end
                end

                f[dt * "/data"] = metadata
            end
            
            f[dt * "/info"] = dataobject.info
        end
    end

    if verbose
        println("-----------------------------------")
        mem = usedmemory(dataobject, false)
        println("Memory size: ", round(mem[1], digits=3)," ", mem[2], " (uncompressed)")
        s = filesize(fpath)
        svalue, sunit = humanize(Float64(s), 3, "memory")
        if wdata println("Total file size: ", svalue, " ", sunit) end
        println("-----------------------------------")
        println()
    end

    return
end

function outputname(fname::String, icpu::Int)
    if icpu < 10
        return string(fname, "0000", icpu)
    elseif icpu < 100 && icpu > 9
        return string(fname, "000", icpu)
    elseif icpu < 1000 && icpu > 99
        return string(fname, "00", icpu)
    elseif icpu < 10000 && icpu > 999
        return string(fname, "0", icpu)
    elseif icpu < 100000 && icpu > 9999
        return string(fname, icpu)
    end
end


function check_file_mode(fmode::Any, datatype::Symbol, fullpath::String, fname::String, verbose::Bool)
    verbose ? println() : nothing

    jld2mode = ""
    if fmode in [nothing]
        wdata = false
    else
        wdata = true
        if fmode == :write
            jld2mode = "w"
        elseif fmode == :append
            jld2mode = "a+"
        else
            error("Unknown fmode...")
        end
    end


    if !isfile(fullpath) && wdata && verbose
        println("Create file: ", fname)
        fexist = false
    elseif !wdata && !isfile(fullpath) && verbose
        println("Not existing file: ", fname)
        fexist = false
    else
        verbose ? println("Existing file: ", fname) : nothing
        fexist = true
    end

    return fexist, wdata, jld2mode
end


function check_compression(compress, wdata)
    if compress == nothing && wdata
        ctype = ZlibCompressor(level=9)
    elseif typeof(compress) == ZlibCompressor && wdata
        ctype = compress
    elseif typeof(compress) == Bzip2Compressor && wdata
        ctype = compress
    elseif compress == false || !wdata
        ctype = :nothing
    end

    return ctype
end


function checkpath(path, filename)
    if path == "./"
        fpath = path * filename
    elseif path == "" || path == " "
        fpath = filename
    else
        if string(path[end]) == "/"
            fpath = path * filename
        else
            fpath = path * "/" * filename
        end
    end
    
    return fpath
end


function check_datasource(dataobject::DataSetType)
    if typeof(dataobject) == HydroDataType
        datatype = :hydro
        use_descriptor = dataobject.info.descriptor.usehydro
        descriptor_names = dataobject.info.descriptor.hydro
    elseif typeof(dataobject) == GravDataType
        datatype = :gravity
        use_descriptor = dataobject.info.descriptor.usegravity
        descriptor_names = dataobject.info.descriptor.gravity
    elseif typeof(dataobject) == PartDataType
        datatype = :particles
        use_descriptor = dataobject.info.descriptor.useparticles
        descriptor_names = dataobject.info.descriptor.particles
    elseif typeof(dataobject) == ClumpDataType
        datatype = :clumps
        use_descriptor = dataobject.info.descriptor.useclumps
        descriptor_names = dataobject.info.descriptor.clumps
    end

    return datatype, use_descriptor, descriptor_names
end
