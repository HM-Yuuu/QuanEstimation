################ update the coefficients according to the given basis ###############
function CFIM_AD_Mopt(AD::LinearComb_Mopt{T}, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed) where {T<:Complex}
    sym = Symbol("CFIM_noctrl")
    str1 = "CFI"
    str2 = "tr(WI^{-1})"
    return info_LinearComb_AD(AD, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed, sym, str1, str2)
end

function gradient_CFI!(AD::LinearComb_Mopt{T}, epsilon, B, POVM_basis, M_num, basis_num) where {T<:Complex}
    δI = gradient(x->CFI([sum([x[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num], AD.freeHamiltonian, AD.Hamiltonian_derivative[1], AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), B)[1]
    B += epsilon*δI
    B = bound_LC_coeff(B)
    return B
end

function gradient_CFI_Adam!(AD::LinearComb_Mopt{T}, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num) where {T<:Complex}
    δI = gradient(x->CFI([sum([x[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num], AD.freeHamiltonian, AD.Hamiltonian_derivative[1], AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), B)[1]
    B = MOpt_Adam!(B, δI, epsilon, mt, vt, beta1, beta2, AD.accuracy)
    B = bound_LC_coeff(B)
    return B
end

function gradient_CFIM!(AD::LinearComb_Mopt{T}, epsilon, B, POVM_basis, M_num, basis_num) where {T<:Complex}
    δI = gradient(x->1/(AD.W*pinv(CFIM([sum([x[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num], AD.freeHamiltonian, AD.Hamiltonian_derivative, AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), rtol=AD.accuracy) |> tr |>real), B) |>sum
    B += epsilon*δI
    B = bound_LC_coeff(B)
    return B
end

function gradient_CFIM_Adam!(AD::LinearComb_Mopt{T}, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num) where {T<:Complex}
    δI = gradient(x->1/(AD.W*pinv(CFIM([sum([x[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num], AD.freeHamiltonian, AD.Hamiltonian_derivative, AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), rtol=AD.accuracy) |> tr |>real), B) |>sum
    B = MOpt_Adam!(B, δI, epsilon, mt, vt, beta1, beta2, AD.accuracy)
    B = bound_LC_coeff(B)
    return B
end

function info_LinearComb_AD(AD, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed, sym, str1, str2) where {T<:Complex}
    println("measurement optimization")
    Random.seed!(seed)
    dim = size(AD.ρ0)[1]
    M_num = AD.M_num
    POVM_basis = AD.povm_basis
    basis_num = length(POVM_basis)
    # initialize 
    B = [rand(basis_num) for i in 1:M_num]
    B = bound_LC_coeff(B)

    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
    f_ini = obj_func(Val{sym}(), AD, Measurement)
    
    f_opt = obj_func(Val{:QFIM_noctrl}(), AD, Measurement)
    f_povm = obj_func(Val{sym}(), AD, POVM_basis)

    episodes = 1
    if length(AD.Hamiltonian_derivative) == 1
        println("single parameter scenario")
        println("search algorithm: Automatic Differentiation (AD)")
        println("initial $str1 is $(1.0/f_ini)")
        println("CFI under the given POVMs is $(1.0/f_povm)")
        println("QFI is $(1.0/f_opt)")
        f_list = [1.0/f_ini]

        if Adam == true
            B = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
        else
            B = gradient_CFI!(AD, epsilon, B, POVM_basis, M_num, basis_num)
        end
        if save_file == true
            Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            SaveFile_meas(f_ini, Measurement)
            if Adam == true
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
                end
            else
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFI!(AD, epsilon, B, POVM_basis, M_num, basis_num)
                end
            end
        else
            if Adam == true
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
                end
            else
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFI!(AD, epsilon, B, POVM_basis, M_num, basis_num)
                end
            end
        end
    else
        println("multiparameter scenario")
        println("search algorithm: Automatic Differentiation (AD)")
        println("initial value of $str2 is $(f_ini)")
        println("tr(WI^{-1}) under the given POVMs is $(f_povm)")
        println("tr(WF^{-1}) is $(f_opt)")
        f_list = [f_ini]

        if Adam == true
            B = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
        else
            B = gradient_CFIM!(AD, epsilon, B, POVM_basis, M_num, basis_num)
        end
        if save_file == true
            Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
            SaveFile_meas(f_ini, Measurement)
            if Adam == true
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
                end
            else
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFIM!(AD, epsilon, B, POVM_basis, M_num, basis_num)
                end
            end
        else
            if Adam == true
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, B, POVM_basis, M_num, basis_num)
                end
            else
                while true
                    Measurement = [sum([B[i][j]*POVM_basis[j] for j in 1:basis_num]) for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    B = gradient_CFIM!(AD, epsilon, B, POVM_basis, M_num, basis_num)
                end
            end
        end
    end
end

################ update the coefficients of the unitary matrix ###############
function CFIM_AD_Mopt(AD::RotateBasis_Mopt{T}, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed) where {T<:Complex}
    sym = Symbol("CFIM_noctrl")
    str1 = "CFI"
    str2 = "tr(WI^{-1})"
    return info_givenpovm_AD(AD, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed, sym, str1, str2)
end

function gradient_CFI!(AD::RotateBasis_Mopt{T}, epsilon, Mbasis, s, Lambda, M_num, dim) where {T<:Complex}
    δI = gradient(x->CFI_AD(Mbasis, x, Lambda, AD.freeHamiltonian, AD.Hamiltonian_derivative[1], AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), s)[1]
    s += epsilon*δI
    s = bound_rot_coeff(s)
    return s
end

function gradient_CFI_Adam!(AD::RotateBasis_Mopt{T}, epsilon, mt, vt, beta1, beta2, Mbasis, s, Lambda, M_num, dim) where {T<:Complex}
    δI = gradient(x->CFI_AD(Mbasis, x, Lambda, AD.freeHamiltonian, AD.Hamiltonian_derivative[1], AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), s)[1]
    s = MOpt_Adam!(s, δI, epsilon, mt, vt, beta1, beta2, AD.accuracy)
    s = bound_rot_coeff(s)
    return s
end

function gradient_CFIM!(AD::RotateBasis_Mopt{T}, epsilon, Mbasis, s, Lambda, M_num, dim) where {T<:Complex}
    δI = gradient(x->1/(AD.W*pinv(CFIM_AD(Mbasis, x, Lambda, AD.freeHamiltonian, AD.Hamiltonian_derivative, AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), rtol=AD.accuracy) |> tr |>real), s) |>sum
    s += epsilon*δI
    s = bound_rot_coeff(s)
    return s
end

function gradient_CFIM_Adam!(AD::RotateBasis_Mopt{T}, epsilon, mt, vt, beta1, beta2, Mbasis, s, Lambda, M_num, dim) where {T<:Complex}
    δI = gradient(x->1/(AD.W*pinv(CFIM_AD(Mbasis, x, Lambda, AD.freeHamiltonian, AD.Hamiltonian_derivative, AD.ρ0, AD.decay_opt, AD.γ, AD.tspan, AD.accuracy), rtol=AD.accuracy) |> tr |>real), s) |>sum
    s = MOpt_Adam!(s, δI, epsilon, mt, vt, beta1, beta2, AD.accuracy)
    s = bound_rot_coeff(s)
    return s
end

function info_givenpovm_AD(AD, mt, vt, epsilon, beta1, beta2, max_episode, Adam, save_file, seed, sym, str1, str2) where {T<:Complex}
    println("measurement optimization")
    Random.seed!(seed)
    dim = size(AD.ρ0)[1]
    suN = suN_generator(dim)
    Lambda = [Matrix{ComplexF64}(I,dim,dim)]
    append!(Lambda, [suN[i] for i in 1:length(suN)])

    POVM_basis = AD.povm_basis
    M_num = length(POVM_basis)
    # initialize 
    s = rand(dim*dim)
    U = rotation_matrix(s, Lambda)
    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
    f_ini = obj_func(Val{sym}(), AD, Measurement)
    f_opt = obj_func(Val{:QFIM_noctrl}(), AD, Measurement)
    f_povm = obj_func(Val{sym}(), AD, POVM_basis)
    episodes = 1
    if length(AD.Hamiltonian_derivative) == 1
        println("single parameter scenario")
        println("search algorithm: Automatic Differentiation (AD)")
        println("initial $str1 is $(1.0/f_ini)")
        println("CFI under the given POVMs is $(1.0/f_povm)")
        println("QFI is $(1.0/f_opt)")
        f_list = [1.0/f_ini]

        if Adam == true
            s = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
        else
            s = gradient_CFI!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
        end
        if save_file == true
            U = rotation_matrix(s, Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            SaveFile_meas(1.0/f_ini, Measurement)
            if Adam == true
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
                end
            else
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFI!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
                end
            end
        else
            if Adam == true
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFI_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
                end
            else
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    f_now = 1.0/f_now
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final $str1 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current $str1 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFI!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
                end
            end
        end
    else
        println("multiparameter scenario")
        println("search algorithm: Automatic Differentiation (AD)")
        println("initial value of $str2 is $(f_ini)")
        println("tr(WI^{-1}) under the given POVMs is $(f_povm)")
        println("tr(WF^{-1}) is $(f_opt)")
        f_list = [f_ini]

        if Adam == true
            s = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
        else
            s = gradient_CFIM!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
        end
        if save_file == true
            U = rotation_matrix(s, Lambda)
            Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
            SaveFile_meas(f_ini, Measurement)
            if Adam == true
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
                end
            else
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        SaveFile_meas(f_now, Measurement)
                        break
                    else
                        episodes += 1
                        SaveFile_meas(f_now, Measurement)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFIM!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
                end
            end
        else
            if Adam == true
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFIM_Adam!(AD, epsilon, mt, vt, beta1, beta2, POVM_basis, s, Lambda, M_num, dim)
                end
            else
                while true
                    U = rotation_matrix(s, Lambda)
                    Measurement = [U*POVM_basis[i]*U' for i in 1:M_num]
                    f_now = obj_func(Val{sym}(), AD, Measurement)
                    if  episodes >= max_episode
                        print("\e[2K")
                        println("Iteration over, data saved.")
                        println("Final value of $str2 is ", f_now)
                        append!(f_list, f_now)
                        SaveFile_meas(f_list, Measurement)
                        break
                    else
                        episodes += 1
                        append!(f_list, f_now)
                        print("current value of $str2 is ", f_now, " ($(episodes) episodes)    \r")
                    end
                    s = gradient_CFIM!(AD, epsilon, POVM_basis, s, Lambda, M_num, dim)
                end
            end
        end
    end
end
