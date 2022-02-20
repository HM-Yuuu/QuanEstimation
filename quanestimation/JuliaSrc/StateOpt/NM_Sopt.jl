############# time-independent Hamiltonian (noiseless) ################
function QFIM_NM_Sopt(NM::TimeIndepend_noiseless{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("QFIM_TimeIndepend_noiseless")
    str1 = "quantum"
    str2 = "QFI"
    str3 = "tr(WF^{-1})"
    M = [zeros(ComplexF64, size(NM.psi)[1], size(NM.psi)[1])]
    return info_NM_noiseless(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
end

function CFIM_NM_Sopt(M, NM::TimeIndepend_noiseless{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("CFIM_TimeIndepend_noiseless")
    str1 = "classical"
    str2 = "CFI"
    str3 = "tr(WI^{-1})"
    return info_NM_noiseless(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
end

function HCRB_NM_Sopt(NM::TimeIndepend_noiseless{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("HCRB_TimeIndepend_noiseless")
    str1 = ""
    str2 = "HCRB"
    str3 = "HCRB"
    M = [zeros(ComplexF64, size(NM.psi)[1], size(NM.psi)[1])]
    if length(NM.Hamiltonian_derivative) == 1
        println("In single parameter scenario, HCRB is equivalent to QFI. Please choose QFIM as the objection function for state optimization.")
        return nothing
    else
        return info_NM_noiseless(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
    end
end

function info_NM_noiseless(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3) where {T<:Complex}
    println("$str1 state optimization")
    Random.seed!(seed)
    dim = length(NM.psi)
    nelder_mead = repeat(NM, state_num)

    # initialize 
    if length(ini_state) > state_num
        ini_state = [ini_state[i] for i in 1:state_num]
    end 
    for pj in 1:length(ini_state)
        nelder_mead[pj].psi = [ini_state[pj][i] for i in 1:dim]
    end
    for pj in (length(ini_state)+1):state_num
        r_ini = 2*rand(dim)-ones(dim)
        r = r_ini/norm(r_ini)
        phi = 2*pi*rand(dim)
        nelder_mead[pj].psi = [r[i]*exp(1.0im*phi[i]) for i in 1:dim]
    end

    p_fit = [0.0 for i in 1:state_num] 
    for pj in 1:state_num
        f_tp = obj_func(Val{sym}(), nelder_mead[pj], M)
        p_fit[pj] = 1.0/f_tp
    end
    sort_ind = sortperm(p_fit, rev=true)

    f_ini = obj_func(Val{sym}(), NM, M)

    if length(NM.Hamiltonian_derivative) == 1
        println("single parameter scenario")
        println("search algorithm: Nelder-Mead method (NM)")
        println("initial $str2 is $(1.0/f_ini)")
    
        f_list = [1.0/f_ini]
        episodes = 1
        if save_file == true
            SaveFile_state(f_list, NM.psi)
            while true
                p_fit, sort_ind = train_noiseless_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final $str2 is ", maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("current $str2 is ", maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        else
            while true
                p_fit, sort_ind = train_noiseless_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final $str2 is ", maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, maximum(p_fit))
                    print("current $str2 is ", maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        end
    else
        println("multiparameter scenario")
        println("search algorithm: Nelder-Mead method (NM)")
        println("initial value of $str3 is $(f_ini)")

        f_list = [f_ini]
        episodes = 1
        if save_file == true
            SaveFile_state(f_list, NM.psi)
            while true
                p_fit, sort_ind = train_noiseless_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final value of $str3 is ", 1.0/maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("current value of $str3 is ", 1.0/maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        else
            while true
                p_fit, sort_ind = train_noiseless_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final value of $str3 is ", 1.0/maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, 1.0/maximum(p_fit))
                    print("current value of $str3 is ", 1.0/maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        end
    end
end

function train_noiseless_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
    # calculate the average vector
    vec_ave = zeros(ComplexF64, dim)
    for ni in 1:dim
        vec_ave[ni] = [nelder_mead[pk].psi[ni] for pk in 1:(state_num-1)] |> sum
        vec_ave[ni] = vec_ave[ni]/(state_num-1)
    end
    vec_ave = vec_ave/norm(vec_ave)

    # reflection
    vec_ref = zeros(ComplexF64, dim)
    for nj in 1:dim
        vec_ref[nj] = vec_ave[nj] + ar*(vec_ave[nj]-nelder_mead[sort_ind[end]].psi[nj])
    end
    vec_ref = vec_ref/norm(vec_ref)
    fr = obj_func(Val{sym}(), NM, M, vec_ref)
    fr = 1.0/fr

    if fr > p_fit[sort_ind[1]]
        # expansion
        vec_exp = zeros(ComplexF64, dim)
        for nk in 1:dim
            vec_exp[nk] = vec_ave[nk] + ae*(vec_ref[nk]-vec_ave[nk])
        end
        vec_exp = vec_exp/norm(vec_exp)
        fe = obj_func(Val{sym}(), NM, M, vec_exp)
        fe = 1.0/fe
        if fe <= fr
            for np in 1:dim
                nelder_mead[sort_ind[end]].psi[np] = vec_ref[np]
            end
            p_fit[sort_ind[end]] = fr
            sort_ind = sortperm(p_fit, rev=true)
        else
            for np in 1:dim
                nelder_mead[sort_ind[end]].psi[np] = vec_exp[np]
            end
            p_fit[sort_ind[end]] = fe
            sort_ind = sortperm(p_fit, rev=true)
        end
    elseif fr < p_fit[sort_ind[end-1]]
        # constraction
        if fr <= p_fit[sort_ind[end]]
            # inside constraction
            vec_ic = zeros(ComplexF64, dim)
            for nl in 1:dim
                vec_ic[nl] = vec_ave[nl] - ac*(vec_ave[nl]-nelder_mead[sort_ind[end]].psi[nl])
            end
            vec_ic = vec_ic/norm(vec_ic)
            fic = obj_func(Val{sym}(), NM, M, vec_ic)
            fic = 1.0/fic
            if fic > p_fit[sort_ind[end]]
                for np in 1:dim
                    nelder_mead[sort_ind[end]].psi[np] = vec_ic[np]
                end
                p_fit[sort_ind[end]] = fic
                sort_ind = sortperm(p_fit, rev=true)
            else
                # shrink
                vec_first = [nelder_mead[sort_ind[1]].psi[i] for i in 1:dim]
                for pk in 1:state_num
                    for nq in 1:dim
                        nelder_mead[pk].psi[nq] = vec_first[nq] + as0*(nelder_mead[pk].psi[nq]-vec_first[nq])
                    end
                    nelder_mead[pk].psi = nelder_mead[pk].psi/norm(nelder_mead[pk].psi)

                    f_tp = obj_func(Val{sym}(), nelder_mead[pk], M)
                    p_fit[pk] = 1.0/f_tp
                end
                sort_ind = sortperm(p_fit, rev=true)
            end
        else
            # outside constraction
            vec_oc = zeros(ComplexF64, dim)
            for nn in 1:dim
                vec_oc[nn] = vec_ave[nn] + ac*(vec_ref[nn]-vec_ave[nn])
            end
            vec_oc = vec_oc/norm(vec_oc)
            foc = obj_func(Val{sym}(), NM, M, vec_oc)
            foc = 1.0/foc
            if foc >= fr
                for np in 1:dim
                    nelder_mead[sort_ind[end]].psi[np] = vec_oc[np]
                end
                p_fit[sort_ind[end]] = foc
                sort_ind = sortperm(p_fit, rev=true)
            else
                # shrink
                vec_first = [nelder_mead[sort_ind[1]].psi[i] for i in 1:dim]
                for pk in 1:state_num
                    for nq in 1:dim
                        nelder_mead[pk].psi[nq] = vec_first[nq] + as0*(nelder_mead[pk].psi[nq]-vec_first[nq])
                    end
                    nelder_mead[pk].psi = nelder_mead[pk].psi/norm(nelder_mead[pk].psi)

                    f_tp = obj_func(Val{sym}(), nelder_mead[pk], M)
                    p_fit[pk] = 1.0/f_tp
                end
                sort_ind = sortperm(p_fit, rev=true)
            end
        end
    else
        for np in 1:dim
            nelder_mead[sort_ind[end]].psi[np] = vec_ref[np]
        end
        p_fit[sort_ind[end]] = fr
        sort_ind = sortperm(p_fit, rev=true)
    end
    return p_fit, sort_ind
end

############# time-independent Hamiltonian (noise) ################

function QFIM_NM_Sopt(NM::TimeIndepend_noise{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("QFIM_TimeIndepend_noise")
    str1 = "quantum"
    str2 = "QFI"
    str3 = "tr(WF^{-1})"
    M = [zeros(ComplexF64, size(NM.psi)[1], size(NM.psi)[1])]
    return info_NM_noise(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
end

function CFIM_NM_Sopt(M, NM::TimeIndepend_noise{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("CFIM_TimeIndepend_noise")
    str1 = "classical"
    str2 = "CFI"
    str3 = "tr(WI^{-1})"
    return info_NM_noise(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
end

function HCRB_NM_Sopt(NM::TimeIndepend_noise{T}, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file) where {T<:Complex}
    sym = Symbol("HCRB_TimeIndepend_noise")
    str1 = ""
    str2 = "HCRB"
    str3 = "HCRB"
    M = [zeros(ComplexF64, size(NM.psi)[1], size(NM.psi)[1])]
    if length(NM.Hamiltonian_derivative) == 1
        println("In single parameter scenario, HCRB is equivalent to QFI. Please choose QFIM as the objection function for state optimization.")
        return nothing
    else
        return info_NM_noise(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3)
    end
end

function info_NM_noise(M, NM, state_num, ini_state, ar, ae, ac, as0, max_episode, seed, save_file, sym, str1, str2, str3) where {T<:Complex}
    println("$str1 state optimization")
    Random.seed!(seed)
    dim = length(NM.psi)
    nelder_mead = repeat(NM, state_num)

    # initialize 
    if length(ini_state) > state_num
        ini_state = [ini_state[i] for i in 1:state_num]
    end 
    for pj in 1:length(ini_state)
        nelder_mead[pj].psi = [ini_state[pj][i] for i in 1:dim]
    end

    for pj in (length(ini_state)+1):state_num
        r_ini = 2*rand(dim)-ones(dim)
        r = r_ini/norm(r_ini)
        phi = 2*pi*rand(dim)
        nelder_mead[pj].psi = [r[i]*exp(1.0im*phi[i]) for i in 1:dim]
    end

    p_fit = [0.0 for i in 1:state_num] 
    for pj in 1:state_num
        f_tp = obj_func(Val{sym}(), nelder_mead[pj], M)
        p_fit[pj] = 1.0/f_tp
    end
    sort_ind = sortperm(p_fit, rev=true)
    f_ini = obj_func(Val{sym}(), NM, M)

    if length(NM.Hamiltonian_derivative) == 1
        println("single parameter scenario")
        println("search algorithm: Nelder-Mead method (NM)")
        println("initial $str2 is $(1.0/f_ini)")
    
        f_list = [1.0/f_ini]
        episodes = 1
        if save_file == true
            SaveFile_state(f_list, NM.psi)
            while true
                p_fit, sort_ind = train_noise_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final $str2 is ", maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("current $str2 is ", maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        else
            while true
                p_fit, sort_ind = train_noise_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)    
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final $str2 is ", maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, maximum(p_fit))
                    print("current $str2 is ", maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        end
    else
        println("multiparameter scenario")
        println("search algorithm: Nelder-Mead method (NM)")
        println("initial value of $str3 is $(f_ini)")

        f_list = [f_ini]
        episodes = 1
        if save_file == true
            SaveFile_state(f_list, NM.psi)
            while true
                p_fit, sort_ind = train_noise_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final value of $str3 is ", 1.0/maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("current value of $str3 is ", 1.0/maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        else
            while true
                p_fit, sort_ind = train_noise_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
                if  episodes >= max_episode
                    append!(f_list, 1.0/maximum(p_fit))
                    SaveFile_state(f_list, nelder_mead[sort_ind[1]].psi)
                    print("\e[2K")
                    println("Iteration over, data saved.")
                    println("Final value of $str3 is ", 1.0/maximum(p_fit))
                    break
                else
                    episodes += 1
                    append!(f_list, 1.0/maximum(p_fit))
                    print("current value of $str3 is ", 1.0/maximum(p_fit), " ($(episodes-1) episodes)    \r")
                end
            end
        end
    end
end

function train_noise_NM(M, nelder_mead, NM, p_fit, sort_ind, dim, state_num, ar, ae, ac, as0, sym)
    # calculate the average vector
    ####test
    vec_ave = zeros(ComplexF64, dim)
    for ni in 1:dim
        vec_ave[ni] = [nelder_mead[pk].psi[ni] for pk in 1:(state_num-1)] |>sum
        vec_ave[ni] = vec_ave[ni]/(state_num-1)
    end
    vec_ave = vec_ave/norm(vec_ave)

    # reflection
    vec_ref = zeros(ComplexF64, dim)
    for nj in 1:dim
        vec_ref[nj] = vec_ave[nj] + ar*(vec_ave[nj]-nelder_mead[sort_ind[end]].psi[nj])
    end
    vec_ref = vec_ref/norm(vec_ref)
    fr = obj_func(Val{sym}(), NM, M, vec_ref)
    fr = 1.0/fr
    if fr > p_fit[sort_ind[1]]
        # expansion
        vec_exp = zeros(ComplexF64, dim)
        for nk in 1:dim
            vec_exp[nk] = vec_ave[nk] + ae*(vec_ref[nk]-vec_ave[nk])
        end
        vec_exp = vec_exp/norm(vec_exp)
        fe = obj_func(Val{sym}(), NM, M, vec_exp)
        fe = 1.0/fe
        if fe <= fr
            for np in 1:dim
                nelder_mead[sort_ind[end]].psi[np] = vec_ref[np]
            end
            p_fit[sort_ind[end]] = fr
            sort_ind = sortperm(p_fit, rev=true)
        else
            for np in 1:dim
                nelder_mead[sort_ind[end]].psi[np] = vec_exp[np]
            end
            p_fit[sort_ind[end]] = fe
            sort_ind = sortperm(p_fit, rev=true)
        end
    elseif fr < p_fit[sort_ind[end-1]]
        # constraction
        if fr <= p_fit[sort_ind[end]]
            # inside constraction
            vec_ic = zeros(ComplexF64, dim)
            for nl in 1:dim
                vec_ic[nl] = vec_ave[nl] - ac*(vec_ave[nl]-nelder_mead[sort_ind[end]].psi[nl])
            end
            vec_ic = vec_ic/norm(vec_ic)
            fic = obj_func(Val{sym}(), NM, M, vec_ic)
            fic = 1.0/fic
            if fic > p_fit[sort_ind[end]]
                for np in 1:dim
                    nelder_mead[sort_ind[end]].psi[np] = vec_ic[np]
                end
                p_fit[sort_ind[end]] = fic
                sort_ind = sortperm(p_fit, rev=true)
            else
                # shrink
                vec_first = [nelder_mead[sort_ind[1]].psi[i] for i in 1:dim]
                for pk in 1:state_num
                    for nq in 1:dim
                        nelder_mead[pk].psi[nq] = vec_first[nq] + as0*(nelder_mead[pk].psi[nq]-vec_first[nq])
                    end
                    nelder_mead[pk].psi = nelder_mead[pk].psi/norm(nelder_mead[pk].psi)
                    f_tp = obj_func(Val{sym}(), nelder_mead[pk], M)
                    p_fit[pk] = 1.0/f_tp
                end
                sort_ind = sortperm(p_fit, rev=true)
            end
        else
            # outside constraction
            vec_oc = zeros(ComplexF64, dim)
            for nn in 1:dim
                vec_oc[nn] = vec_ave[nn] + ac*(vec_ref[nn]-vec_ave[nn])
            end
            foc = obj_func(Val{sym}(), NM, M, vec_oc)
            foc = 1.0/foc
            if foc >= fr
                for np in 1:dim
                    nelder_mead[sort_ind[end]].psi[np] = vec_oc[np]
                end
                p_fit[sort_ind[end]] = foc
                sort_ind = sortperm(p_fit, rev=true)
            else
                # shrink
                vec_first = [nelder_mead[sort_ind[1]].psi[i] for i in 1:dim]
                for pk in 1:state_num
                    for nq in 1:dim
                        nelder_mead[pk].psi[nq] = vec_first[nq] + as0*(nelder_mead[pk].psi[nq]-vec_first[nq])
                    end
                    nelder_mead[pk].psi = nelder_mead[pk].psi/norm(nelder_mead[pk].psi)

                    f_tp = obj_func(Val{sym}(), nelder_mead[pk], M)
                    p_fit[pk] = 1.0/f_tp
                end
                sort_ind = sortperm(p_fit, rev=true)
            end
        end
    else
        for np in 1:dim
            nelder_mead[sort_ind[end]].psi[np] = vec_ref[np]
        end
        p_fit[sort_ind[end]] = fr
        sort_ind = sortperm(p_fit, rev=true)
    end
    return p_fit, sort_ind
end