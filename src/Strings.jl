################################################################################
# String management for Speckles.jl
################################################################################


"""
    makeName(params::Dict; excpt::Dict = Dict())

Returns a string based on parameters in the simulation dictionary.
"""
function makeName(params::Dict; excpt::Dict = Dict())
    date = today()
    mm = length(month(date)) == 1 ? string(0,month(date)) : month(date)
    dd = length(day(date)) == 1 ? string(0,day(date)) : day(date)
    out = string(year(date),mm,dd,"_")
    for key in keys(params)
        keyname = key
        val = params[key]
        if isa(val,Array)
            val = length(val)
            keyname = string("len-",keyname)
        end
        out = string(out,keyname,"=",val,"_")
    end
    return out
end

export makeName