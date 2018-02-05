%params
no_of_channels = 1;
datafile = 'C:\Data\Clio cv match data\Day 3\ContRecord#2\ContRecord2_204';

params.filt_freq = 2000; %we found 2000Hz for 2 channel data gave a smoother CV
params.sample_freq = 58820*2; 
params.prog_bar = 0;
params2.cv_match_template = 'Chemometrics\cv_match';
params2.cv_match_template = 'C:\Data\CV_template_clio.mat';
params2.cv_match_template = '..\..\Data\Clio cv match data\mark_best_cv';
params2.shiftpeak = 0;
params2.plotfig = 1;
params2.colormap_type = 'fcv';
bg_scan_dist = 15;
timeinterval = [];
root_path = '..\..\Data\Clio cv match data\For TJP\';
load(params2.cv_match_template);
day_list = dir(root_path);
%for each day
for k = 3:length(day_list)
k
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
        cv_progressbar(0, 0)
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
        %for each smaller recording cv match whole file with a set baseline distance
        for j = 1:length(files)
            cv_progressbar(j/length(files),0);
            [fcv_header, ch1_fcv_data, ~] = tarheel_read([data_path '\' cont_folders(i).name '\' files{j}],no_of_channels);
            [ts,TTLs] = TTLsRead([data_path '\' cont_folders(i).name '\' files{j} '.txt']);         
        
            %take windowsize from next file so we can bg subtract data in the last [bg_scan_dist] seconds of the file
            if j ~= length(files)
                [fcv_header, ch1_fcv_data_next, ~] = tarheel_read([data_path '\' cont_folders(i).name '\' files{j+1}],no_of_channels);    
                ch1_fcv_data = [ch1_fcv_data,ch1_fcv_data_next(:,1:bg_scan_dist)];
            end
            [roh, bg_scan, cvs] = auto_cv_match_tarheel_cv_match2(ch1_fcv_data, params, params2,[], bg_scan_dist, timeinterval);
            all_roh = [all_roh;roh];
            all_bg_scan = [all_bg_scan;bg_scan];
            all_cvs = [all_cvs,cvs];

            if plot_figs
                figure
                subplot(2,1,1)
                plot(all_roh)
                subplot(2,1,2)
                imagesc(cvs)
                ax = gca;
                ax.YDir = 'normal';
                load fcv_colormap
                colormap(norm_fcv)

                [vals] = scale_fcv_colorbar(cvs);
                colorbar
                caxis(vals)

                xlabel('time(s)')
                ylabel('Applied Voltage')
            end

        end
        timetake(i) = toc;
        all_ts = [0:0.1:(length(all_roh)*0.1)-0.1]';
%         figure
%         subplot(2,1,1)
%         plot(all_ts, all_roh)
%         hold on
%         plot([all_ts(1),max(all_ts)],[rval_threshold,rval_threshold])
%         xlim([all_ts(1) max(all_ts)]);
%         subplot(2,1,2)
%         imagesc(all_cvs)
%         ax = gca;
%         ax.YDir = 'normal';
%         load fcv_colormap
%         colormap(norm_fcv)
% 
%         [vals] = scale_fcv_colorbar(cvs);
%         %colorbar
%         caxis(vals)    


        folder_var = matlab.lang.makeValidName(cont_folders(i).name);
        clio_recordings.(dayvar).(folder_var).cvs = all_cvs;
        clio_recordings.(dayvar).(folder_var).r_vals = all_roh;

        %count peaks, get times and values of peak

        peaks = (all_roh >= 0.86);
        peak_shifted = [0 ;[peaks(1:(length(peaks)-1))]];
        peak_diff = peaks-peak_shifted;
        peak_start = find(peak_diff == 1);
        peak_end = find(peak_diff == -1);
        peak_val = [];
        peak_time  = [];
        for k = 1:length(peak_start)
            [peak_val(k), index] = max(all_roh(peak_start(k):peak_end(k)-1));        
            peak_time(k) = all_ts(index+peak_start(k));
        end
%         figure
%         subplot(2,1,1)
%         hist(peak_val)
%         title('transient peak value')
%          subplot(2,1,2)
%         hist(peak_time, max(all_ts)/(60*bin_time))

        %Use hist to bin data and get transient rate
        [binned_data, ts] = hist(peak_time, max(all_ts)/(60*bin_time));
        title('transient peak time')
         clio_recordings.(dayvar).(folder_var).transient_info.peak_values = peak_val;
         clio_recordings.(dayvar).(folder_var).transient_info.peak_times = peak_time;
         clio_recordings.(dayvar).(folder_var).transient_info.transient_rate = binned_data;
         clio_recordings.(dayvar).(folder_var).transient_info.binsize_in_mins = bin_time;
         clio_recordings.(dayvar).(folder_var).cv_match_template = cv_match;
        
        %plot moving average
        %mov_avg = movmean(vector, win_size);
        %try different average gausian average, try just a high pass filter.

    end
end






































