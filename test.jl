using Revise # To avoid reloading the session while we test things
include("./src/EcologicalNetwork.jl")
using EcologicalNetwork
using StatsBase
using NamedTuples
using Combinatorics
using Base.Test

N = web_of_life("A_HP_002")
#N = nz_stream_foodweb()[1]
N = convert(BinaryNetwork, N)

function swap_degree!(Y::BinaryNetwork)
    iy = interactions(Y)
    i1, i2 = sample(iy, 2, replace=false)
    n1, n2 = @NT(from=i1.from, to=i2.to), @NT(from=i2.from, to=i1.to)

    while (n2 ∈ iy)|(n1 ∈ iy)
        i1, i2 = sample(iy, 2, replace=false)
        n1, n2 = @NT(from=i1.from, to=i2.to), @NT(from=i2.from, to=i1.to)
    end

    for old_i in [i1, i2, n1, n2]
        i = findfirst(species(Y,1), old_i.from)
        j = findfirst(species(Y,2), old_i.to)
        Y.A[i,j] = !Y.A[i,j]
    end
end

function swap_fill!(Y::BinaryNetwork)
    iy = interactions(Y)
    i1 = sample(iy)
    n1 = @NT(from=sample(species(Y,1)), to=sample(species(Y,2)))

    while (n1 ∈ iy)
        n1 = @NT(from=sample(species(Y,1)), to=sample(species(Y,2)))
    end

    for old_i in [i1, n1]
        i = findfirst(species(Y,1), old_i.from)
        j = findfirst(species(Y,2), old_i.to)
        Y.A[i,j] = !Y.A[i,j]
    end
end

function swap_indegree!(Y::BinaryNetwork)
    iy = interactions(Y)
    i1 = sample(iy)
    n1 = @NT(from=sample(species(Y,1)), to=i1.to)

    while (n1 ∈ iy)
        n1 = @NT(from=sample(species(Y,1)), to=i1.to)
    end

    for old_i in [i1, n1]
        i = findfirst(species(Y,1), old_i.from)
        j = findfirst(species(Y,2), old_i.to)
        Y.A[i,j] = !Y.A[i,j]
    end
end

function swap_outdegree!(Y::BinaryNetwork)
    iy = interactions(Y)
    i1 = sample(iy)
    n1 = @NT(from=i1.from, to=sample(species(Y,2)))

    while (n1 ∈ iy)
        n1 = @NT(from=i1.from, to=sample(species(Y,2)))
    end

    for old_i in [i1, n1]
        i = findfirst(species(Y,1), old_i.from)
        j = findfirst(species(Y,2), old_i.to)
        Y.A[i,j] = !Y.A[i,j]
    end
end

m = BipartiteNetwork([true false; true true])
f(n) = length(find_motif(n, m))

Yd = copy(N)
Yf = copy(N)
Yi = copy(N)
Yo = copy(N)
ts, st = 50, 10
nd = zeros(ts)
nf = zeros(ts)
ni = zeros(ts)
no = zeros(ts)
nd[1] = f(Yd)
nf[1] = f(Yf)
ni[1] = f(Yi)
no[1] = f(Yo)
@progress for i in 2:ts
    for re in 1:st
        swap_degree!(Yd)
        swap_fill!(Yf)
        swap_indegree!(Yi)
        swap_outdegree!(Yo)
    end
    nd[i] = f(Yd)
    nf[i] = f(Yf)
    ni[i] = f(Yi)
    no[i] = f(Yo)
end

z(x) = (x .- x[i])./std(x)

using Plots
x = collect(1:ts).*st
p1 = plot(x, z(nd), lab="Degree", c=:blue, alpha=0.4)
p2 = plot(x, z(nf), lab="Fill", c=:green, alpha=0.4)
p3 = plot(x, z(ni), lab="In-degree", c=:purple, alpha=0.4)
p4 = plot(x, z(no), lab="Out-degree", c=:orange, alpha=0.4)

plot((p1,p2,p3,p4)..., frame=:origin, leg=false)
yaxis!((-4,4))
