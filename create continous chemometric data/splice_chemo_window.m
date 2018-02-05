function spliced_data = splice_chemo_window(data, moving_window)

moving_window = moving_window*10;
spliced_data = [];
for i = 1:moving_window(1):length(data)
    
    if i == 1
        window_data = data(i:i+(moving_window(1)-1),2);
    elseif ~isnan(data(i-1))
        window_data = data(i:i+(moving_window(1)-1),2);
        difference = window_data(1)-spliced_data(i-1);
        window_data = window_data-difference;
    elseif sum(isnan(data(i-1:i-10)))<10
        nan_result = isnan(data(i-1:i-10,2));
        [index, ~] = find(nan_result == 0);
        window_data = data(i:i+(moving_window(1)-1));
        window_data = window_data-data(i-index(1));
    end
    
    spliced_data = [spliced_data;window_data];
    
end

spliced_data =  nanfastsmooth(spliced_data,20,1,0);