#!/usr/bin/julia
# Simulation requires Yichao's calculation library to run, copy this whole folder https://github.com/nacs-lab/yyc-data/tree/master/lib
push!(LOAD_PATH, joinpath("/Users/jluke/Documents/Harvard/NiLab/Yichao/yyc-data/lib")) #Replace this with path to yyc data on your machine

using PyPlot
PyPlot.matplotlib["rcParams"][:update](Dict("font.size" => 20))
PyPlot.matplotlib[:rc]("xtick", labelsize=15)
PyPlot.matplotlib[:rc]("ytick", labelsize=15)

import NaCsSim: Setup, System
import NaCsCalc: Trap
using NaCsCalc.Utils: interactive
using NaCsCalc.Atomic: all_scatter_D
using LinearAlgebra

#Helper functions for plotting and saving figures 
function maybe_save(name)
    if !interactive()
        dir = dirname(name)
        if !isempty(dir)
            mkpath(dir, 0o755)
        end
        savefig("$name.png"; bbox_inches="tight", transparent=true)
        savefig("$name.pdf"; bbox_inches="tight", transparent=true)
        savefig("$name.svg", bbox_inches="tight", transparent=true)
        close()
    end
end

function maybe_show()
    if interactive()
        show()
    end
end

function plot_ground_state(params, res)
    figure()
    gp = [r.a for r in res]
    gp_unc = [r.s for r in res]
    errorbar(params, gp, gp_unc)
    ylabel("Ground state probability")
    if maximum(gp) > 0.5
        ylim([0, 1])
    end
    plot_hook()
    grid()
end

function plot_total(params, res)
    figure()
    total = [1 - t.a for t in res]
    total_unc = [t.s for t in res]
    errorbar(params, total, total_unc)
    ylabel("Total loss")
    ylim([0, ylim()[2]])
    plot_hook()
    grid()
end

function plot_nbars(params, res)
    figure()
    nbarx_res = (nr[1] for nr in res)
    nbary_res = (nr[2] for nr in res)
    nbarz_res = (nr[3] for nr in res)

    nbarx = [n.a for n in nbarx_res]
    nbarx_unc = [n.s for n in nbarx_res]
    nbary = [n.a for n in nbary_res]
    nbary_unc = [n.s for n in nbary_res]
    nbarz = [n.a for n in nbarz_res]
    nbarz_unc = [n.s for n in nbarz_res]
    if max(maximum(nbarx), maximum(nbary), maximum(nbarz)) > 1
        gca()[:set_yscale]("log")
    end
    errorbar(params, nbarx, nbarx_unc, label="X")
    errorbar(params, nbary, nbary_unc, label="Y")
    errorbar(params, nbarz, nbarz_unc, label="Z")
    legend()
    ylabel("\$\\bar n\$")
    plot_hook()
    grid()
end

function plot_ndist(res,ax)
    nDist = res[end][3:7];
    nDistVals = Vector{Float64}(undef,5);
    nDistUnc = Vector{Float64}(undef,5);
    for i = 1:length(nDist)
        nDistVals[i] = nDist[i].a;
        nDistUnc[i] = nDist[i].s;
    end
    figure(1)
    ylim([0, 1])
    title("Final n distribution")
    ylabel("Probability")
    print(ax)
    if ax == 1
        xname[] = "Axial n = ";
    elseif ax == 2
        xname[] = "R1 n = ";
    elseif ax == 3 
        xname[] = "R2 n = ";
    end
    xlabel(xname)
    plot_hook()
    errorbar(1:length(nDist), nDistVals, nDistUnc)
    grid()
end

plot_hf(params, res) = plot_hf(params, collect(res))

function plot_hf(params, res::Vector{T}) where {T<:Tuple}
    figure()
    for i in 1:nfields(T)
        hf = [r[i].a for r in res]
        hf_unc = [r[i].s for r in res]
        errorbar(params, hf, hf_unc, label="$i")
    end
    legend()
    ylim([0, 1])
    title("Hyperfine")
    ylabel("Probability")
    plot_hook()
    grid()
end

function plot_result(params, res, prefix)
    plot_ground_state(params, (r[2] for r in res))
    maybe_save(joinpath(prefix, "ground"))

    plot_total(params, (r[1][2] for r in res))
    maybe_save(joinpath(prefix, "loss"))

    plot_nbars(params, (r[1][1] for r in res))
    maybe_save(joinpath(prefix, "nbar"))

    #plot_hf(params, (r[3][1] for r in res))
    #maybe_save(joinpath(prefix, "hf"))
end

const xname = Ref("")
function plot_hook()
    xlabel(xname[])
end

#Helper functions for getting observables from simulation output
function get_ground_state(res)
    [r.a for r in res], [r.s for r in res]
end

function get_total(res)
    [1 - t.a for t in res], [t.s for t in res]
end

function get_nbars(res)
    nbarx_res = (nr[1] for nr in res)
    nbary_res = (nr[2] for nr in res)
    nbarz_res = (nr[3] for nr in res)

    nbarx = [n.a for n in nbarx_res]
    nbarx_unc = [n.s for n in nbarx_res]
    nbary = [n.a for n in nbary_res]
    nbary_unc = [n.s for n in nbary_res]
    nbarz = [n.a for n in nbarz_res]
    nbarz_unc = [n.s for n in nbarz_res]

    return nbarx, nbarx_unc, nbary, nbary_unc, nbarz, nbarz_unc
end

get_hf(res) = get_hf(collect(res))

Base.@pure Nx2(N::Int) = N * 2

function get_hf(res::Vector{T}) where {N,T<:NTuple{N,Any}}
    return ntuple(i->i % 2 == 1 ? [r[(i + 1) ÷ 2].a for r in res] : [r[i ÷ 2].s for r in res],
                  Val(Nx2(N)))
end

function save_result(params, res, fname)
    data = (get_ground_state((r[2] for r in res))...,
            get_total((r[1][2] for r in res))...,
            get_nbars((r[1][1] for r in res))...,
            get_hf((r[3][1] for r in res))...)
    open("$fname.csv", "w") do fh
        for i in 1:length(params)
            print(fh, params[i])
            for a in data
                print(fh, ",", a[i])
            end
            println(fh)
        end
    end
end

#Handles multithreading
function threadmap(f, arg)
    # A really simple work queue
    n = length(arg)
    counter = Threads.Atomic{Int}(1)
    T = Core.Compiler.return_type(f, Tuple{eltype(arg)})
    res = Vector{T}(undef,n)
    nt = Threads.nthreads()
    Threads.@threads for _ in 1:nt
        while true
            i = Threads.atomic_add!(counter, 1)
            if i > n
                break
            end
            res[i] = f(arg[i])
        end
    end
    if !isconcretetype(T)
        return [v for v in res]
    end
    return res
end

## End of helper parts

#Constants of NaCs 1.5 experiment - these shouldn't need to change
const m_Na = 23f-3 / 6.02f23
const k_Na = Float32(2π) / 589f-9
const k_trap = Float32(2π) / 616f-9
const trap_freq = (69.5f3, 414f3, 409f3)
η(freq) = Trap.η(m_Na, freq, k_Na)
const η_full = η.(trap_freq)
ηs_Na(a, b, c) = Float32.((a, b, c)) .* η_full
const η_full_trap = Trap.η.(m_Na, trap_freq, k_trap)
ηs_trap(a, b, c) = Float32.((a, b, c)) .* η_full_trap

const η_op = ηs_Na(1, 1, 1)

function gen_isσ(Δdri)
    res = zeros(Bool, 8, 8)
    idx_to_state = function (idx)
        if idx > 5
            # low F
            return idx - 7
        else
            # high F
            return idx - 3
        end
    end
    for i in 1:8
        mF1 = idx_to_state(i)
        for j in 1:8
            mF2 = idx_to_state(j)
            # From i to j, from mF1 to mF2
            if abs(mF1 + Δdri - mF2) == 1
                res[j, i] = true
            end
        end
    end
    res
end

const isσs_all = [gen_isσ(-1), gen_isσ(0), gen_isσ(1)]

#Detunings of beams (a potential optimization parameter)
const δf1 = -32e9
const δf2 = -32e9 - 1.77e9
const δzeeman = 12.33e6
const δD1f2 = -664.360e6 - (118.05e6 - 70.836e6) / 2 + 96e6
const δD1f1 = -664.360e6 - (118.05e6 - 70.836e6) / 2 + 96e6 + 443.7e6*4

#Calculate scattering rates for OP beams - don't need to worry about this part
function gen_fscale(D2::Bool, δ0, zeeman)
    Γ = D2 ? 61.542e6 : 61.353e6
    offset′ = if D2
        (66.097e6, 50.288e6, 15.944e6, -42.382e6)
    else
        (0.0, 118.05e6, -70.830e6, 0.0)
    end
    g1 = if D2
        (2 / 3, 2 / 3, 2 / 3, 2 / 3)
    else
        (0.0, -1 / 6, 1 / 6, 0.0)
    end
    return function (F1x2, mF1x2, F′x2, mF′x2)
        offset = F1x2 == 2 ? -1.107266e9 : 664.360e6
        g0 = F1x2 == 2 ? -0.5 : 0.5
        offset += offset′[F′x2 ÷ 2 + 1]
        offset += (g0 * mF1x2 - g1[F′x2 ÷ 2 + 1] * mF′x2) * zeeman / 2
        return Γ / (δ0 + offset + Γ / (4π) * im)
    end
end

# Decay rates and Rabi frequencies are measured in MHz (or us⁻¹)
# Times are measured in μs

const rscale_f1_coprop = 4.46e8 / 1e6 # Amp 0.25
const rscale_f2_coprop = 4.1e8 / 1e6 # Amp 0.22
const rscale_f1_up = 1.05e9 / 1e6 # Amp 1.0
const rscale_f1_down = 8.2e8 / 1e6 # Amp 0.22
const rscale_f2_counterop = 3.25e9 / 1e6 # Amp 0.05

struct BeamSpec{T}
    η::NTuple{3,T}
    rates::Vector{Tuple{Matrix{T},Matrix{Bool}}}
end
function (::Type{BeamSpec{T}})(D2::Bool, η, pol::NTuple{3,Any}, δ0, scale) where T
    rates2 = Tuple{Matrix{T},Matrix{Bool}}[]
    all_pols = ((1, 0, 0),
                (0, 1, 0),
                (0, 0, 1))
    for i in 1:3
        p = pol[i]
        p == 0 && continue
        rate = all_scatter_D(gen_fscale(D2, δ0, δzeeman), D2, 3, all_pols[i])
        push!(rates2, (T.(rate .* p .* scale), isσs_all[i]))
    end
    return BeamSpec{T}(η, rates2)
end

const bs_f1_coprop = BeamSpec{Float32}(true, ηs_Na(-sqrt(0.5), 0.5, 0.5), (0.5, 0.0, 0.5),
                                       δf1, rscale_f1_coprop)
const bs_f2_coprop = BeamSpec{Float32}(true, ηs_Na(-sqrt(0.5), 0.5, 0.5), (0.25, 0.5, 0.25),
                                       δf2, rscale_f2_coprop)
const bs_f1_up = BeamSpec{Float32}(true, ηs_Na(0, sqrt(0.5), -sqrt(0.5)), (0.25, 0.5, 0.25),
                                   δf1, rscale_f1_up)
const bs_f1_down = BeamSpec{Float32}(true, ηs_Na(0, -sqrt(0.5), sqrt(0.5)), (0.25, 0.5, 0.25),
                                     δf1, rscale_f1_down)
const bs_f2_counterop = BeamSpec{Float32}(true, ηs_Na(0, -sqrt(0.5), -sqrt(0.5)), (0.1, 0.0, 0.9),
                                          δf2, rscale_f2_counterop)


gen_f1op_spec(p, pol) =
    BeamSpec{Float32}(false, ηs_Na(0, sqrt(0.5), sqrt(0.5)), pol, δD1f1, p)
gen_f2op_spec(p, pol) =
    BeamSpec{Float32}(false, ηs_Na(0, sqrt(0.5), sqrt(0.5)), pol, δD1f2, p)

const include_scatter = true

const sz = 300, 30, 30
const trapscatter = System.Scatter{Float32}(Diagonal(ones(Float32,8)) .* 0.033e-3 * include_scatter * ((508848 - 428275)/(508848 - 2.98f-1*k_trap/Float32(2π)))^2,
                                            ηs_trap(1, 1, 1), ηs_trap(1, 0, 0),
                                            zeros(Bool, 8, 8),
                                            (0, 1, 1))
const op_pol = include_scatter ? (0.99358, 0, 0.00642) : (1, 0, 0)
#const op_pol = include_scatter ? (1, 0, 0) : (1, 0, 0)

#These functions generate particular types of pulses to be built into the sequence
function create_raman_raw(t, p1, p2, ramp1, ramp2, bs1::BeamSpec, bs2::BeamSpec, Ω0, Δn)
    Ω = sqrt(p1 * p2) * Ω0
    if ramp1
        p1 /= 3
        Ω /= 2
        @assert !ramp2
    end
    if ramp2
        p2 /= 3
        Ω /= 2
    end
    s1s = [System.Scatter{Float32}(p1 * r[1], η_op, abs.(bs1.η), r[2],
                                   (0, 1, 1)) for r in bs1.rates]
    s2s = [System.Scatter{Float32}(p2 * r[1], η_op, abs.(bs2.η), r[2],
                                   (0, 1, 1)) for r in bs2.rates]
    scatter = [s1s; s2s; trapscatter]
    return System.RealRaman{Float32,1,6}(t, Ω, abs.(bs1.η .- bs2.η), Δn, sz,
                                         include_scatter ? scatter : System.Scatter{Float32}[])
end

struct RamanSpec{T}
    Ω0::T
    bs1::BeamSpec{T}
    bs2::BeamSpec{T}
end

const raman_specs = [RamanSpec{Float32}(0.2417, bs_f1_coprop, bs_f2_coprop), # co-prop
                     RamanSpec{Float32}(0.4856, bs_f1_up, bs_f2_coprop), # axial 1
                     RamanSpec{Float32}(0.5412, bs_f1_up, bs_f2_counterop), # radial 2
                     RamanSpec{Float32}(0.5487, bs_f1_down, bs_f2_counterop) # radial 3
                     ]

get_Δns(ax, Δn::NTuple{3,Any}) = Δn
function get_Δns(ax, Δn)
    if ax == 0
        @assert Δn == 0
        return (0, 0, 0)
    elseif ax == 1 #Axial
        return (Δn, 0, 0)
    elseif ax == 2 #R1
        return (0, Δn, 0)
    elseif ax == 3 #R2
        return (0, 0, Δn)
    else
        error("Invalid axis number $ax")
    end
end

function create_raman(t, p1, p2, ramp1, ramp2, ax, Δn=0)
    rs = raman_specs[ax + 1]
    return create_raman_raw(t, p1, p2, ramp1, ramp2, rs.bs1, rs.bs2, rs.Ω0, get_Δns(ax, Δn))
end
create_wait(t) = System.MultiOP{Float32}(t, [trapscatter])
function create_op(t, p1, p2, pol=op_pol)
    bs1 = gen_f1op_spec(p1, pol)
    bs2 = gen_f2op_spec(p2, pol)
    s1s = [System.Scatter{Float32}(r[1], η_op, abs.(bs1.η), r[2], (0, 1, 1)) for r in bs1.rates]
    s2s = [System.Scatter{Float32}(r[1], η_op, abs.(bs2.η), r[2], (0, 1, 1)) for r in bs2.rates]
    return System.MultiOP{Float32}(t, [s1s; s2s; trapscatter])
end

const BuilderT = Setup.SeqBuilder{System.StateC,Nothing}
statec() = System.StateC(sz...)

function create_sequence(op_t = 28,op_f1_amp = 0.3,op_f2_amp = 0.06,
    r_t = 32,ax_t = 32,r_f1_amp =  1,r_f2_amp =  1,ax_f1_amp = 1,ax_f2_amp = 1,
    n1=8,n2=20,n3=10,n4=12,n5=14,n6=40)
    nDistAx = 3;
    builder = BuilderT(System.ThermalInit{1,Float32}(15, 1.2, 1.2), Setup.Dummy(),
                       Setup.CombinedMeasure(System.NBarMeasure(),
                                             System.GroundStateMeasure(),
                                             System.HyperFineMeasure{8}()))
    # n = typemax(Int)
    nloop = Ref{Int}(n1+n2+n3+n4+n5+n6)
    function take_pulse(np)
        local n
        n = nloop[]
        if n >= np
            nloop[] = n - np
            return np
        else
            nloop[] = 0
            return n
        end
    end
    op = create_op(op_t, op_f1_amp, op_f2_amp);
	#=
    r_t = 32;
    ax_t = 32;
    r_f1_amp =  1;
    r_f2_amp =  1;
    ax_f1_amp = 1;
    ax_f2_amp = 1;
    =#
    # op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp
    function add_raman_cool(t, p1, p2, ramp1, ramp2, ax, Δn)
        Setup.add_pulse(builder, create_raman(t, p1, p2, ramp1, ramp2, ax, Δn))
        Setup.add_pulse(builder, op)
    end

    for i in 1:take_pulse(n1)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -1)
    end
    for i in 1:take_pulse(n2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -1)
    end
    
    for i in 1:take_pulse(n3)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -5)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -4)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -5)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -4)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -1)
    end
    
    for i in 1:take_pulse(n4)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -4)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -3)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -4)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -3)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -2)
        add_raman_cool(r_t,r_f1_amp, r_f2_amp, true, false, 3, -1)
    end

    for i in 1:take_pulse(n5)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -3)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -3)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -1)
    end
    for i in 1:take_pulse(n6)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -2)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -1)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 2, -1)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -2)
        add_raman_cool(ax_t, ax_f1_amp,ax_f2_amp,  true, false, 1, -1)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -2)
        add_raman_cool(r_t, r_f1_amp, r_f2_amp, true, false, 3, -1)
    end
    Setup.add_pulse(builder, System.Filter((hf, v)->sum(v .* trap_freq) <= 20000f3))
    return builder.seq
end

# const params = linspace(0, 3000000, 101)
function interface(argarray)
    op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp, n1, n2,n3,n4,n5,n6 = [parse(Float64, i) for i in argarray]
    n1, n2,n3,n4,n5,n6 = [Int64(i) for i in [ n1, n2,n3,n4,n5,n6 ]]
    res = Setup.run(create_sequence(op_t, op_f1_amp, op_f2_amp, r_t, ax_t, r_f1_amp, r_f2_amp, ax_f1_amp, ax_f2_amp, n1, n2,n3,n4,n5,n6), statec(), nothing, 500)
    xname[] = "Pulse group"

    ground_state = res[2].a;

    nbarx = res[1][1][1].a;
    nbary = res[1][1][2].a;
    nbarz = res[1][1][3].a;
    println(nbarx)
    println( ground_state)
    write(ground_state,nbarx)
    return ground_state, nbarx
end 
function write(ground_state, nbarx)
    io = open("./result.csv", "w")
    println(io, string(ground_state) * "," *string(nbarx))
    close(io)
    println("Completed")
    return ground_state, nbarx
end 

interface(ARGS)
#write(1,2)
#    #plot_ndist(res,3)
#    plot_result(params, res, "")
#else    
#end
