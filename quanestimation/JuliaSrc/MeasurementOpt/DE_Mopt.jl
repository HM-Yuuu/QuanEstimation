################ projection measurement ###############
function CFIM_DE_Mopt(DE::projection_Mopt{T}, popsize, ini_population, c, cr, seed, max_episode, save_file) where {T<:Complex}
    sym = Symbol("CFIM_noctrl")
    str1 = "CFI"
    str2 = "tr(WI^{-1})"
    return info_DE_projection(DE, popsize, ini_population, c, cr, seed, max_episode, save_file, sym, str1, str2)
end

function info_DE_projection(DE, popsize, ini_population, c, cr, seed, max_episode, save_file, sym, str1, str2) where {T<:Complex}
    println("measurement optimization")
    Random.seed!(seed)
    dim = size(DE.ρ0)[1]
    M_num = length(DE.C)

    p_num = popsize
    populations = repeat(DE, p_num)
    # initialize 
    if length(ini_population) > popsize
        ini_population = [ini_population[i] for i in 1:popsize]
    end
    for pj in 1:length(ini_population)
        populations[pj].C = [[ini_population[pj][i,j] for j in 1:dim] for i in 1:M_num]
    end
    for pj in (length(ini_population)+1):p_num
        M_tp = [Vector{ComplexF64}(undef, dim) for i in 1:M_num]
        for mi in 1:M_num
            r_ini = 2*rand(dim)-ones(dim)
            r = r_ini/norm(r_ini)
            phi = 2*pi*rand(dim)
            M_tp[mi] = [r[i]*exp(1.0im*phi[i]) for i in 1:dim]
        end
        populations[pj].C = [[M_tp[i][j] for j in 1:dim] for i in 1:M_num]
        # orthogonality and normalization 
        populations[pj].C = gramschmidt(populations[pj].C)
    end

    p_fit = [0.0 for i in 1:p_num] 
    for pj in 1:p_num
        Measurement = [populations[pj].C[i]*(populations[pj].C[i])' for i in 1:M_num]
        p_fit[pj] = 1.0/obj_func(Val{sym}(), DE, Measurement)
    end

    f_ini= p_fit[1]
    f_opt = obj_func(Val{:QFIM_noctrl}(), DE, DE.C)
    f_opt= 1.0/f_opt

    if length(DE.Hamiltonian_derivative) == 1
        f_list = [f_ini]

        println("single parameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial $str1 is $(f_ini)")
        println("QFI is $(f_opt)")
        
        if save_file == true
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
                append!(f_list, maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
                append!(f_list, maximum(p_fit))
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")   
            end
            p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        end
    else
        f_list = [1.0/f_ini]
        println("multiparameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial value of $str2 is $(1.0/f_ini)")
        println("tr(WF^{-1}) is $(1.0/f_opt)")

        if save_file == true
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
                append!(f_list, 1.0/maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
                append!(f_list, 1.0/maximum(p_fit))
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit = train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [populations[indx].C[i]*(populations[indx].C[i])' for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        end
    end
end

function train_projection(populations, c, cr, p_num, dim, M_num, p_fit, sym)
    for pj in 1:p_num
        #mutations
        mut_num = sample(1:p_num, 3, replace=false)
        M_mut = [Vector{ComplexF64}(undef, dim) for i in 1:M_num]
        for ci in 1:M_num
            for ti in 1:dim
                M_mut[ci][ti] = populations[mut_num[1]].C[ci][ti] + c*(populations[mut_num[2]].C[ci][ti]-
                                populations[mut_num[3]].C[ci][ti])
            end
        end
        #crossover
        M_cross = [Vector{ComplexF64}(undef, dim) for i in 1:M_num]
        for cj in 1:M_num
            cross_int = sample(1:dim, 1, replace=false)[1]
            for tj in 1:dim
                rand_num = rand()
                if rand_num <= cr
                    M_cross[cj][tj] = M_mut[cj][tj]
                else
                    M_cross[cj][tj] = populations[pj].C[cj][tj]
                end
            end
            M_cross[cj][cross_int] = M_mut[cj][cross_int]
        end

        # orthogonality and normalization 
        M_cross = gramschmidt(M_cross)

        Measurement = [M_cross[i]*(M_cross[i])' for i in 1:M_num]

        #selection
        f_cross = obj_func(Val{sym}(), populations[pj], Measurement)
        f_cross = 1.0/f_cross

        if f_cross > p_fit[pj]
            p_fit[pj] = f_cross
            for ck in 1:M_num
                for tk in 1:dim
                    populations[pj].C[ck][tk] = M_cross[ck][tk]
                end
            end
        end
    end
    return p_fit
end


################## update the coefficients according to the given basis ############
function CFIM_DE_Mopt(DE::LinearComb_Mopt{T}, popsize, c, cr, seed, max_episode, save_file) where {T<:Complex}
    sym = Symbol("CFIM_noctrl")
    str1 = "CFI"
    str2 = "tr(WI^{-1})"
    return info_DE_LinearComb(DE, popsize, c, cr, seed, max_episode, save_file, sym, str1, str2)
end

function info_DE_LinearComb(DE, popsize, c, cr, seed, max_episode, save_file, sym, str1, str2) where {T<:Complex}
    println("measurement optimization")
    Random.seed!(seed)
    dim = size(DE.ρ0)[1]
    POVM_basis = DE.povm_basis
    basis_num = length(POVM_basis)
    M_num = DE.M_num
    p_num = popsize
    populations = repeat(DE, p_num)
    # initialize 
    B_all = [[zeros(basis_num) for i in 1:M_num] for j in 1:p_num]
    for pj in 1:p_num
        B_all[pj] = [rand(basis_num) for i in 1:M_num]
        B_all[pj] = bound_LC_coeff(B_all[pj])
    end

    p_fit = [0.0 for i in 1:p_num] 
    for pj in 1:p_num
        Measurement = [sum([B_all[pj][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
        p_fit[pj] = 1.0/obj_func(Val{sym}(), DE, Measurement)
    end

    f_ini= p_fit[1]
    f_opt = obj_func(Val{:QFIM_noctrl}(), DE, POVM_basis)
    f_opt = 1.0/f_opt

    f_povm = obj_func(Val{sym}(), DE, POVM_basis)
    f_povm = 1.0/f_povm

    if length(DE.Hamiltonian_derivative) == 1
        f_list = [f_ini]

        println("single parameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial $str1 is $(f_ini)")
        println("CFI under the given POVMs is $(f_povm)")
        println("QFI is $(f_opt)")
        
        if save_file == true
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                append!(f_list, maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
                append!(f_list, maximum(p_fit))
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")   
            end
            p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        end
    else
        f_list = [1.0/f_ini]
        println("multiparameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial value of $str2 is $(1.0/f_ini)")
        println("tr(WI^{-1}) under the given POVMs is $(1.0/f_povm)")
        println("tr(WF^{-1}) is $(1.0/f_opt)")

        if save_file == true
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                append!(f_list, 1.0/maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
                append!(f_list, 1.0/maximum(p_fit))
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, B_all = train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            Measurement = [sum([B_all[indx][i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        end
    end
end

function train_LinearComb(populations, B_all, POVM_basis, c, cr, p_num, basis_num, M_num, p_fit, sym)
    for pj in 1:p_num
        #mutations
        mut_num = sample(1:p_num, 3, replace=false)
        M_mut = [Vector{Float64}(undef, basis_num) for i in 1:M_num]
        for ci in 1:M_num
            for ti in 1:basis_num
                M_mut[ci][ti] = B_all[mut_num[1]][ci][ti] + c*(B_all[mut_num[2]][ci][ti]-B_all[mut_num[3]][ci][ti])
            end
        end
        #crossover
        M_cross = [Vector{Float64}(undef, basis_num) for i in 1:M_num]
        for cj in 1:M_num
            cross_int = sample(1:basis_num, 1, replace=false)[1]
            for tj in 1:basis_num
                rand_num = rand()
                if rand_num <= cr
                    M_cross[cj][tj] = M_mut[cj][tj]
                else
                    M_cross[cj][tj] = B_all[pj][cj][tj]
                end
            end
            M_cross[cj][cross_int] = M_mut[cj][cross_int]
        end

        # normalize the coefficients 
        M_cross = bound_LC_coeff(M_cross)
        Measurement = [sum([M_cross[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]

        #selection
        f_cross = obj_func(Val{sym}(), populations[pj], Measurement)
        f_cross = 1.0/f_cross
        
        if f_cross > p_fit[pj]
            p_fit[pj] = f_cross
            for ck in 1:M_num
                for tk in 1:basis_num
                    B_all[pj][ck][tk] = M_cross[ck][tk]
                end
            end
        end
    end
    return p_fit, B_all
end


################## update the coefficients of the unitary matrix ############
function CFIM_DE_Mopt(DE::RotateBasis_Mopt{T}, popsize, c, cr, seed, max_episode, save_file) where {T<:Complex}
    sym = Symbol("CFIM_noctrl")
    str1 = "CFI"
    str2 = "tr(WI^{-1})"
    return info_DE_RotateBasis(DE, popsize, c, cr, seed, max_episode, save_file, sym, str1, str2)
end

function info_DE_RotateBasis(DE, popsize, c, cr, seed, max_episode, save_file, sym, str1, str2) where {T<:Complex}
    println("measurement optimization")
    Random.seed!(seed)
    dim = size(DE.ρ0)[1]
    suN = suN_generator(dim)
    Lambda = [Matrix{ComplexF64}(I,dim,dim)]
    append!(Lambda, [suN[i] for i in 1:length(suN)])

    POVM_basis = DE.povm_basis
    M_num = length(POVM_basis)
    p_num = popsize
    populations = repeat(DE, p_num)
    s_all = [zeros(dim*dim) for i in 1:p_num]
    # initialize 
    p_fit = [0.0 for i in 1:p_num] 
    for pj in 1:p_num
        # generate a rotation matrix randomly
        s_all[pj] = rand(dim*dim)
        U = rotation_matrix(s_all[pj], Lambda)
        Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
        p_fit[pj] = 1.0/obj_func(Val{sym}(), DE, Measurement)
    end

    f_ini= p_fit[1]
    f_opt = obj_func(Val{:QFIM_noctrl}(), DE, POVM_basis)
    f_opt = 1.0/f_opt

    f_povm = obj_func(Val{sym}(), DE, POVM_basis)
    f_povm = 1.0/f_povm

    if length(DE.Hamiltonian_derivative) == 1
        f_list = [f_ini]

        println("single parameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial $str1 is $(f_ini)")
        println("CFI under the given POVMs is $(f_povm)")
        println("QFI is $(f_opt)")
        
        if save_file == true
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                U = rotation_matrix(s_all[indx], Lambda)
                Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                append!(f_list, maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
                append!(f_list, maximum(p_fit))
                print("current $str1 is ", maximum(p_fit), " ($i eposides)    \r")   
            end
            p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            append!(f_list, maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final $str1 is ", maximum(p_fit))
        end
    else
        f_list = [1.0/f_ini]
        println("multiparameter scenario")
        println("search algorithm: Differential Evolution (DE)")
        println("initial value of $str2 is $(1.0/f_ini)")
        println("tr(WI^{-1}) under the given POVMs is $(1.0/f_povm)")
        println("tr(WF^{-1}) is $(1.0/f_opt)")

        if save_file == true
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            SaveFile_meas(f_list, Measurement)
            for i in 1:(max_episode-1)
                p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
                indx = findmax(p_fit)[2]
                U = rotation_matrix(s_all[indx], Lambda)
                Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                append!(f_list, 1.0/maximum(p_fit))
                SaveFile_meas(f_list, Measurement)
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        else
            for i in 1:(max_episode-1)
                p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
                append!(f_list, 1.0/maximum(p_fit))
                print("current value of $str2 is ", 1.0/maximum(p_fit), " ($i eposides)    \r")
            end
            p_fit, s_all = train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
            indx = findmax(p_fit)[2]
            U = rotation_matrix(s_all[indx], Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            append!(f_list, 1.0/maximum(p_fit))
            SaveFile_meas(f_list, Measurement)
            print("\e[2K")
            println("Iteration over, data saved.")
            println("Final value of $str2 is ", 1.0/maximum(p_fit))
        end
    end
end

function train_RotateBasis(populations, s_all, POVM_basis, Lambda, c, cr, p_num, dim, M_num, p_fit, sym)
    for pj in 1:p_num
        #mutations
        mut_num = sample(1:p_num, 3, replace=false)
        M_mut = Vector{Float64}(undef, dim^2)
        for ti in 1:dim^2
            M_mut[ti] = s_all[mut_num[1]][ti] + c*(s_all[mut_num[2]][ti]-s_all[mut_num[3]][ti])
        end

        #crossover
        M_cross = Vector{Float64}(undef, dim^2)
        cross_int = sample(1:dim^2, 1, replace=false)[1]
        for tj in 1:dim^2
            rand_num = rand()
            if rand_num <= cr
                M_cross[tj] = M_mut[tj]
            else
                M_cross[tj] = s_all[pj][tj]
            end
        end
        M_cross[cross_int] = M_mut[cross_int]

        # normalize the coefficients 
        M_cross = bound_rot_coeff(M_cross)
        U = rotation_matrix(M_cross, Lambda)
        Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
        
        #selection
        f_cross = obj_func(Val{sym}(), populations[pj], Measurement)
        f_cross = 1.0/f_cross
        
        if f_cross > p_fit[pj]
            p_fit[pj] = f_cross
            for tk in 1:dim^2
                s_all[pj][tk] = M_cross[tk]
            end
        end
    end
    return p_fit, s_all
end
