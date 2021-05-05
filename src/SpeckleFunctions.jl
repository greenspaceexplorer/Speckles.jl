################################################################################
# Correlation Functions
################################################################################
"""
	function correlate(u::Vector{T},v::Vector{T},offset::Integer,window::Integer = -1) where {T<:Number}

Calculates correlation between vectors u and v with given offset. Specify averaging window to limit range of correlation. If the window extends beyond the end of one vector, it treats out-of-bounds indices as zero.
"""
function correlate(u::Vector{T},v::Vector{T},offset::Integer,window::Integer = -1) where {T<:Number}

	@assert offset <= length(u) "Offset out of bounds"
	@assert window <= length(u) && window <= length(v) "Window must be smaller than input vector lengths"

	if window == -1
		window = length(u)
	end

	v1 = view(u,1:window)
	v2 = view(v,1+offset:min(window+offset,length(v)))
	if window+offset > length(v)
		v2 = vcat(v2,zeros(window+offset-length(v)))
	end

	return dot(v1,v2)/window
end

export correlate

"""
	function autocorrelate(u::Vector{T},offset::Integer, window::Integer = -1) where {T<:Number}

Calculates correlation of vector u with itself.
"""
function autocorrelate(u::Vector{T},offset::Integer, window::Integer = -1) where {T<:Number}
	correlate(u,u,offset,window)
end

export autocorrelate

"""
    function corrTimes(τ::Vector,γCounts::Vector)

Returns an array of τ values for which the γCounts autocorrelation is non-zero.
"""
function corrTimes(τ::Vector,γCounts1::Vector,γCounts2::Vector)
    @assert length(γCounts1) == length(γCounts2) "Count vectors must have the same length"
    return τ[map(i->correlate(γCounts1,γCounts2,i,length(τ)) > 0 ? true : false,collect(0:length(τ)-1))]
end

export corrTimes

"""
    function autocorrTimes(τ::Vector,γCounts::Vector)

Returns an array of τ values for which the γCounts autocorrelation is non-zero.
"""
function autocorrTimes(τ::Vector,γCounts::Vector)
    return τ[map(i->autocorrelate(γCounts,i,length(τ)) > 0 ? true : false,collect(0:length(τ)-1))]
end

export autocorrTimes

################################################################################
# Counting Related Functions
################################################################################
"""
    function countDeltaTimes(τ::Vector,γCounts::Vector)

Returns an array of τ values for which the γCounts autocorrelation is non-zero.
"""
function countTimes(times::Vector,γCounts::Vector)
    out = Vector{Real}(undef,0)
    for (i,counts) in enumerate(γCounts)
        if counts != 0
            countTimes = times[i]*ones(counts)
            out = vcat(out,countTimes)
        end
    end
    return out
end

export countTimes

################################################################################
# Functions from MGST2021
################################################################################

"""
    stauAvg(τ::Number,params::eFieldParams,n::Integer)

Returns the average of the Doppler noise term
"""
function stauAvg(τ::Number,params::eFieldParams,n::Integer)
    return stauAvg(τ,params.σ,n)
end

"""
    stauAvg(τ::Number,σ::Number,n::Integer)

Returns the average of the Doppler noise term
"""
function stauAvg(τ::Number,σ::Number,n::Integer)
    term1 = n
    term2 = n*(n-1)
    term2 *= exp(-σ^2*τ^2)
    return term1 + term2
end

export stauAvg

"""
    stauVar(τ::Number,params::eFieldParams,n::Integer)

Returns the variance of the Doppler noise term
"""
function stauVar(τ::Number,params::eFieldParams,n::Integer)
    return stauVar(τ,params.σ,n)
end

"""
    stauVar(τ::Number,σ::Number,n::Integer)

Returns the variance of the Doppler noise term
"""
function stauVar(τ::Number,σ::Number,n::Integer)
    στ2 = σ^2*τ^2

    prod1 = 8*n*(n-1)
    prod1 *= exp(-2*στ2)

    prod2 = n-1+cosh(στ2)

    prod3 = sinh(στ2/2)^2

    return prod1*prod2*prod3
end

export stauVar

"""
    stau(τ::Number,instance::eFieldInstance)

Calculates the value of the Doppler noise term for the given eFieldInstance
"""
function stau(τ::Number,instance::eFieldInstance)
    return stau(τ,instance.ωn)
end

"""
    stau(τ::Number,ωn::Vector)

Calculates the value of the Doppler noise term for the given τ and frequencies
"""
function stau(τ::Number,ωn::Vector)
    terms = exp.(-im*τ*ωn)
    sumterms = sum(terms)
    return real(sumterms*conj(sumterms))
end

export stau

"""
    g2Calc(τ::Number,n::Integer,params::eFieldParams)

Returns the average calculated value of g2(τ) from MGST2021.
"""
function g2Calc(τ::Number,n::Integer,params::eFieldParams)
    em2 = real.(params.Em .* conj.(params.Em))
    em4 = em2 .* em2
    sumEm2 = sum(em2)
    sumEm4 = sum(em4)

    g2τ = 1.0

    term2 = -sumEm4/(n*sumEm2^2)

    g2τ += term2

    Δm = params.ωm .- params.ω0
    term3 = sum(em2 .* exp.(-im*τ*Δm))/sumEm2
    term3 *= conj(term3)
    term3 = real(term3)
    term3 *= stauAvg(τ,params,n)/n^2

    return g2τ+term3
end

export g2Calc