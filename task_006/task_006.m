clear all;

%FRAME DIFFERENCING

v_reader = VideoReader("../Video2.mp4");
total_num_frames = v_reader.NumFrames;
mid_frames = floor(total_num_frames/2);
first_frame = read(v_reader, 1);
final_frame = read(v_reader, total_num_frames);

second_frame = read(v_reader, 10);

v_player1 = vision.VideoPlayer("Name", "Previous Frame", "Position", [100,200,300,300]);
v_player2 = vision.VideoPlayer("Name", "Current Frame Difference", "Position", [400,200,300,300]);
v_player3 = vision.VideoPlayer("Name", "Current Frame Difference Highlighted", "Position", [700,200,300,300]);
v_player4 = vision.VideoPlayer("Name", "Current Frame Difference Highlighted Smoothed", "Position", [700,200,300,300]);

%Framerate
f_rate = v_reader.FrameRate;

frame_index_arr = [1,total_num_frames];
len_of_index_arr = length(frame_index_arr);
changing_index = 1;
%global differ_frame;
%differ_frame = read(v_reader,1);
count = 9;
%while hasFrame(v_reader)





mean_img = imread("MEAN_IMAGE.jpg");
imshow(mean_img);

[r,c,sz] = size(mean_img);
mean_img2 = zeros(r,c,sz);
mean_img2 = mean_img2 + double(first_frame);
mean_img2 = mean_img2 + double(final_frame);
mean_img2 = uint8(mean_img2/2);
s = figure;
imshow(mean_img2);

while count <= total_num_frames
    disp(count);
    current_frame = read(v_reader, count);
    [r,c,sz] = size(current_frame);
    disp(frame_index_arr);
    %%{
   
    %current_frame = read(v_reader, count);
    %if count ~= 1
    %disp("Not first frame");
    v_player1(current_frame);
        
    BGI = get_BGI(current_frame, mean_img);
    
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




function BGI = get_BGI(current_frame, prev_frame)
    [r,c,sz] = size(current_frame);

    BGI = zeros(r,c);
    [f_r, f_g, f_b] = get_current_frame_components(current_frame, r, c);
    [bg_r, bg_g, bg_b] = get_prev_frame_components(prev_frame, r, c);
    Cmax = get_max_channel_difference(f_r, f_g, f_b, bg_r, bg_g, bg_b);

    %Set thresholding value
    th = 37;

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