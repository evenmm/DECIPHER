function [L, gradL] = vectorized_objective_function_k_subpopulations(Params,no_populations,DATA,concvec,timevec,NR)
    %Params are model parameters. DATA is cell counts at each dependent
    %variable condition. size(DATA) = (NR,NC,NT). 
    %concvec is list of concentration considered.
    %timevec is list of times, and NR is number of replicates at each condition.
    %To predict, we multiply DATA(k,j,1) by {p*popfunc(Param1,concvec(j),timevec(i)) + (1-p)*popfunc(Param2,concvec(j),timevec(i))}
    %Predictions are the same for all replicates, but residuals differ between replicates.

    %alpha_m = Params(5*m-4);
    %b_m = Params(5*m-3);
    %E_m = Params(5*m-2);
    %n_m = Params(5*m-1);
    %p_m = Params(5*m); %except p_k which is 1 minus sum(p_m)
    sig=Params(length(Params));
    NC=length(concvec);
    NT=length(timevec);
    k_ = no_populations-1;

    % Initial cell counts to be used in prediction
    time_zero_DATA = DATA(:,:,1); %size (NR,NC,1)
    rep_time_zero_DATA = repmat(time_zero_DATA,1,1,NT); %size (NR,NC,NT)

    % Prediction at time T by exponential growth with rate affected by hill function of concentration, per cell line 
    if no_populations > 1
        pred_multiplier = zeros(1,NC,NT);
        for m=1:k_
            pred_multiplier = pred_multiplier + Params(5*m)*vectorized_popfunc(Params(5*m-4:5*m-1),concvec,timevec);
        end
        pred_multiplier = pred_multiplier + (1-sum(Params(5:5:5*k_)))*vectorized_popfunc(Params(5*no_populations-4:5*no_populations-1),concvec,timevec);
    else
        pred_multiplier = vectorized_popfunc(Params(1:4),concvec,timevec);
    end
    %pred_multiplier = p*vectorized_popfunc(Param1,concvec,timevec) ...
    %                    + (1-p)*vectorized_popfunc(Param2,concvec,timevec); % size (1,NC,NT)

    repeated_multiplier = repmat(pred_multiplier,NR,1,1); % size (NR,NC,NT)

    pred_data = rep_time_zero_DATA .* repeated_multiplier; % size (NR,NC,NT)
    %pred_data = max(0, pred_data); % Should we rectify negative values?
    
    resid = DATA(:,:,2:NT) - pred_data(:,:,2:NT); % Residuals at time zero do not enter in the calculation (and are zero anyway)
    sum_squared_resid = sum(resid.^2, 'all', 'omitnan'); % size 1
    resid_term = sum_squared_resid ./ (2*sig^2);

    % L is the negative normal loglikelihood
    % (resid_term already includes division by 2)
    L = resid_term + (NC*(NT-1)*NR)/2*log(2*pi*sig^2);

end
