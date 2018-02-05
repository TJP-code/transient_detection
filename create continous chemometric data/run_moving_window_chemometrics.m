clear 
close all

no_of_channels = 1;
datafile = 'C:\Data\Clio cv match data\Day 3\ContRecord#2\ContRecord2_204';
%load 'C:\Users\tjahansprice\Google Drive\Data\Clio cv match data\da_transient_data'

%params from bg subtract
bg_subtract.filt_freq = 2000; %we found 2000Hz for 2 channel data gave a smoother CV
bg_subtract.sample_freq = 58820*2; 
bg_subtract.prog_bar = 0;
plot_fcv.cv_match_template = 'Chemometrics\cv_match';
plot_fcv.cv_match_template = 'C:\Data\CV_template_clio.mat';
plot_fcv.cv_match_template = 'C:\Users\tjahansprice\Google Drive\Data\Clio cv match data\mark_best_cv';
plot_fcv.shiftpeak = 0;
plot_fcv.plotfig = 0;
plot_fcv.colormap_type = 'fcv';

moving_window = [30 30];
root_path = 'C:\Users\tjahansprice\Google Drive\Data\Clio cv match data\For TJP\';
load(plot_fcv.cv_match_template);
day_list = dir(root_path);

pcr_params.cvmatrix = dlmread('C:\Users\tjahansprice\Google Drive\FCV\Chemometrics\cv_analysis_cv_matrix\cvmatrix1.txt');
pcr_params.concmatrix = dlmread('C:\Users\tjahansprice\Google Drive\FCV\Chemometrics\cv_analysis_cv_matrix\concmatrix1.txt');
pcr_params.pcs = [];
pcr_params.alpha = [];

%for each day
for k = 3:length(day_list)
    
    day = day_list(k).name;
    data_path = [root_path day];
    cont_folders = dir([data_path '\Cont*']);
    plot_figs = 0;
    dayvar = matlab.lang.makeValidName(day);
    rval_threshold = 0.86;
    bin_time = 1;%in mins
    all_ts = [];
    
    %for each continuous recording
    for i = 1:length(cont_folders)
        %%%cv_progressbar(0, 0)
        recording_files = dir([data_path '\' cont_folders(i).name]);
        files = {recording_files.name};
        %remove folders
        isfolder = cell2mat({recording_files.isdir});
        files(isfolder)=[];
        %remove txt files
        myindices = find(~cellfun(@isempty,strfind(files,'txt')));
        files([myindices])=[]; 
        ch1_fcv_data_all = [];
        all_roh = [];all_bg_scan = [];all_cvs = [];
        tic
        %for each file
        for j = 1:length(files)
            %run chemometrics on [window size] length of data
            %move background subtraction and run chemometrics again
        
            %%%cv_progressbar(j/length(files),0);
            
            %read file
            [fcv_header, ch1_fcv_data, ~] = tarheel_read([data_path '\' cont_folders(i).name '\' files{j}],no_of_channels);
            [ts,TTLs] = TTLsRead([data_path '\' cont_folders(i).name '\' files{j} '.txt']);         

            ch1_fcv_data_all = [ch1_fcv_data_all,ch1_fcv_data];
        end
        timetake(i) = toc;
        all_ts = [0:0.1:(length(ch1_fcv_data_all)*0.1)-0.1]';
        
        
        %find session to update
%         sessions = fieldnames(clio_recordings);
%         [recordingsession,~] = find(strcmp(sessions,dayvar));
         folder_var = matlab.lang.makeValidName(cont_folders(i).name);
        
        chemometric_data = moving_window_chemometrics(ch1_fcv_data_all, all_ts, moving_window, bg_subtract, pcr_params);
        %min_data = 1;
        %[averaged_data, raw_data] = average_chemometric_window(chemometric_data,min_data);
        spliced_data = splice_chemo_window(chemometric_data, moving_window);
        
        clio_recordings.(dayvar).(folder_var).mw_chemometrics = [all_ts,spliced_data];
        clio_recordings.(dayvar).(folder_var).matrix_mw_chemometrics = vec2mat(spliced_data,300)';
        clio_recordings.(dayvar).(folder_var).matrix_ts_chemometrics = vec2mat(all_ts,300)';
        
    end
end

%deal with NaNs
%plot_fcvdata(data)