function chemometric_data = moving_window_chemometrics(fcv_data, ts, moving_window, bg_params, pcr_params)

%run chemometrics on [window size] length of data
%move background subtraction and run chemometrics again
sample_rate = 10; %Hz
moving_window = moving_window*sample_rate;
chemometric_data = [];
for i = 1:moving_window(2):(length(fcv_data)-moving_window(1))+moving_window(2)

    %bg subtract
    bg_params.bg_pos = 1;
    window_data = fcv_data(:,[i:i+(moving_window(1)-1)]);
    window_ts = ts(i:(i+moving_window(1))-1);
    [temp_processed_data] = process_raw_fcv_data(window_data, bg_params);

    %create training set
    [Vc, F, Qcrit, K] = pca_training_set(pcr_params.cvmatrix,pcr_params.concmatrix,pcr_params.pcs, pcr_params.alpha);

    %apply pcr
    [C_predicted, Q, Q_cutoff, model_cvs, residuals] = apply_pcr(temp_processed_data, Vc, F, Qcrit);
    
    chemometric_data = [chemometric_data;window_ts,Q_cutoff(1,:)'];
   
    
end