clear all;

%FRAME DIFFERENCING

v_reader = VideoReader("../Video1.mp4");
total_num_frames = v_reader.NumFrames;

first_frame = read(v_reader, 1);
second_frame = read(v_reader, 10);

v_player1 = vision.VideoPlayer("Name", "Previous Frame", "Position", [100,200,300,300]);
v_player2 = vision.VideoPlayer("Name", "Current Frame Difference", "Position", [400,200,300,300]);
v_player3 = vision.VideoPlayer("Name", "Current Frame Difference Highlighted", "Position", [700,200,300,300]);
v_player4 = vision.VideoPlayer("Name", "Current Frame Difference Highlighted Smoothed", "Position", [700,200,300,300]);

%Framerate
f_rate = v_reader.FrameRate;

frame_index_arr = [1,2,3, 4];
len_of_index_arr = length(frame_index_arr);
changing_index = 1;
%global differ_frame;
%differ_frame = read(v_reader,1);
count = 7;
%while hasFrame(v_reader)
while count ~= total_num_frames
    disp(count);
    %Gaussian Noise
    %current_frame = imnoise(read(v_reader, count), "gaussian", 0.05);
    
    %Salt and pepper noise
    current_frame = imnoise(read(v_reader, count), "salt & pepper");
    v_player2(current_frame);
    [r,c,sz] = size(current_frame);
    %GET VALUES OF AVERAGE IMAGE
    
    mean_img = zeros(r,c,sz);

    for i=1: len_of_index_arr
        %APPLY GAUSSIAN NOISE
        %this_img = double(imnoise(read(v_reader, frame_index_arr(i)), "gaussian", 0.005));
        
        %APPLY SALT AND PEPPER NOISE
        salt_and_pepper_frame = double(imnoise(read(v_reader, frame_index_arr(i)), "salt & pepper", 0.1));

        %REMOVE SALT AND PEPPER NOISE
        this_img = removed_salt_and_pepper(salt_and_pepper_frame);

        mean_img = mean_img+double(this_img);
    end
    %igure();
    mean_img = uint8(mean_img / len_of_index_arr);
    imshow(uint8(mean_img), []);


    %REMOVE SALT AND PEPPER NOISE FROM CURRENT FRAME
    current_frame = removed_salt_and_pepper(current_frame);

    %REMOVING GAUSSIAN NOISE FROM CURRENT FRAME
    %current_frame = remove_gaussian_noise(current_frame);

    %disp(frame_index_arr);
    %if count > 10
    %    break;
    %end
    arr_count = 1;

    differences = [];

    for i=1: len_of_index_arr
        differences(i) = frame_index_arr(i) - count;
    end
    %disp(frame_index_arr);
    [el, indx] = min(differences);
    frame_index_arr(indx) = count-2;
    disp(frame_index_arr);
    %%{
   
    %current_frame = read(v_reader, count);
    %if count ~= 1
    %disp("Not first frame");
    v_player1(current_frame);
        
    BGI = get_BGI(current_frame, mean_img);
    %v_player2(BGI);

    %Highlight pixels in frame that differ from the BG
    frame3 = mean_img;
    frame3(:,:,1)=BGI.*mean_img(:,:,1);
    frame3(:,:,2)=BGI.*mean_img(:,:,2);
    frame3(:,:,3)=BGI.*mean_img(:,:,3);
    v_player3(frame3);

    
    [f_r, f_g, f_b] = get_current_frame_components(current_frame, r, c);
    frame4 = mean_img;
    frame4(:,:,1)=BGI.*uint8(f_r);
    frame4(:,:,2)=BGI.*uint8(f_g);
    frame4(:,:,3)=BGI.*uint8(f_b);
    v_player4(frame4);
   


    %}
    
    %Increment count by 1
    count = count +1;
end




function removed_gaussian = remove_gaussian_noise(frame)
    removed_gaussian = wiener2(frame, [5,5]);
end


function removed_salt_and_pepper = removed_salt_and_pepper(frame)
    rgb_range = 3;
    for i=1: rgb_range
        removed_salt_and_pepper(:,:,i)=medfilt2(frame(:,:,i), [3,3]);
    end

end


function removed_salt_and_pepper = removed_salt_and_pepper2(frame)
    rgb_range = 3;
    for i=1: rgb_range
        removed_salt_and_pepper(:,:,i)=medfilt2(frame(:,:,i), [4,4]);
    end

end

function BGI = get_BGI(current_frame, prev_frame)
    [r,c,sz] = size(current_frame);

    BGI = zeros(r,c);
    [f_r, f_g, f_b] = get_current_frame_components(current_frame, r, c);
    [bg_r, bg_g, bg_b] = get_prev_frame_components(prev_frame, r, c);
    Cmax = get_max_channel_difference(f_r, f_g, f_b, bg_r, bg_g, bg_b);

    %Set thresholding value
    th = 47;

    %Get motion silhoutte
    BGI(Cmax>th) = 255;
    BGI= uint8(BGI);
end



function Cmax = get_max_channel_difference(f_r, f_g, f_b, bg_r, bg_g, bg_b)
    %{
    Compute the difference between the smoothed current frame and the 
    smoothed backgrouund for each of the R,G, B components
    %}
    C1 = abs(f_r-bg_r);
    C2 = abs(f_g - bg_g);
    C3 = abs(f_b - bg_b);

    %Calculate the maximum difference over the 3 channels
    Cabs12 = max(C1, C2);
    Cabs = max(Cabs12, C3);
    Cmax = uint8(Cabs); 
end


function [f_r, f_g, f_b] = get_current_frame_components(current_frame, r, c)
    %Specify size for averaging filter
    size_of_avg_filter = 2;
    avg_filter = fspecial("average", size_of_avg_filter);
    %avg_filter = medfilt2(current_frame, [size_of_avg_filter, size_of_avg_filter]);

    %{
    1. Separate R,G,B components and smooth each componenet using local avg
    filter
    %}  
    f_r_pad = conv2(avg_filter, current_frame(:,:,1));
    f_g_pad = conv2(avg_filter, current_frame(:,:,2));
    f_b_pad = conv2(avg_filter, current_frame(:,:,3));


    %Exclude the border that has been added by padding
    f_r = f_r_pad((size_of_avg_filter +1)/2: r+(size_of_avg_filter-1)/2, (size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);
    f_g = f_g_pad((size_of_avg_filter+1)/2: r+(size_of_avg_filter-1)/2, (size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);
    f_b = f_b_pad((size_of_avg_filter+1)/2: r+(size_of_avg_filter-1)/2, (size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);

end


function [bg_r, bg_g, bg_b] = get_prev_frame_components(prev_frame, r, c)
    %Specify size for averaging filter
    size_of_avg_filter = 2;
    avg_filter = fspecial("average", size_of_avg_filter);
    %avg_filter = medfilt2(current_frame, [size_of_avg_filter, size_of_avg_filter]);
    %{
    SEPARATE R, G AND B COMPONENTS
    SMOOTH EACH COMPONENT USING A LOCAL AVERAGING FILTER
    %}
    bg_r_pad = conv2(avg_filter, prev_frame(:,:,1));
    bg_g_pad = conv2(avg_filter, prev_frame(:,:,2));
    bg_b_pad = conv2(avg_filter, prev_frame(:,:,3));

    %Convolution using the conv2 function uses padding and so creates a border
    %of width (size_of_avg_filter-1)/2

    %So we need to select the interior region of the convolved image that
    %excludes the border of padding
    bg_r = bg_r_pad((size_of_avg_filter+1)/2: r+(size_of_avg_filter-1)/2,(size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);
    bg_g = bg_g_pad((size_of_avg_filter+1)/2: r+(size_of_avg_filter-1)/2,(size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);
    bg_b = bg_b_pad((size_of_avg_filter+1)/2: r+(size_of_avg_filter-1)/2,(size_of_avg_filter+1)/2: c+(size_of_avg_filter-1)/2);

end