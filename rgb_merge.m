function [mosaic] = rgb_merge(filename)
%RGB_MERGE Given filename for Prokudin-Gorskii image in directory, 
%merge them together. The input above is the actual text which gives the
%location of the image.

    tic(); %get time info
    original = imread(filename);  
    
    %Cut the image into three pieces
    interval = floor(length(original(:,1))/3);
    B = single(double(original(1:interval,:))./255);
    G = single(double(original(interval+1:interval*2,:))./255);
    R = single(double(original(interval*2+1:end-mod(length(original(:,1)),3),:))./255);

    %Crop out the black borders
    crop = round(0.05*size(original,2));
    R = R(crop:end-crop,crop:end-crop);
    G = G(crop:end-crop,crop:end-crop);
    B = B(crop:end-crop,crop:end-crop);

    downR = R;
    downG = G;
    downB = B;
    num_down = 1;

    %For the large TIFF images, we downsampled until we got close to
    %the size of the low-res JPG images.
    pyramid = cell(5,3); %Store the pyramid of images for each color
    pyramid{1,1} = R;
    pyramid{1,2} = G;
    pyramid{1,3} = B;
    
    while size(downR,1) > 500 || size(downR,2) > 500
        %Used filter-downsample process to make this work
        g = fspecial('gaussian',[9 9]);
        downR = imfilter(downR,g);
        downR = downR(1:2:end,1:2:end);
        downG = imfilter(downG,g);
        downG = downG(1:2:end,1:2:end);
        downB = imfilter(downB,g);
        downB = downB(1:2:end,1:2:end);
        num_down = num_down + 1;
        pyramid{num_down,1} = downR;
        pyramid{num_down,2} = downG;
        pyramid{num_down,3} = downB;
    end

    %Run our RANSAC algorithm on bottom of the pyramid

    R_tmp = pyramid{num_down,1};
    G_tmp = pyramid{num_down,2};
    B_tmp = pyramid{num_down,3};
    [A1, T1, totnum1] = ransac2d(B_tmp,G_tmp,1000, 1);
    [A2, T2, totnum2] = ransac2d(R_tmp,G_tmp,1000, 1); 

    
    if totnum1 < 17 || totnum2 < 17
        disp(sprintf('Not enough Inliers for image: %s',filename));
    else

        %For B to G
        boxB = [1  size(B,2) size(B,2)  1 ;
                1  1           size(B,1)  size(B,1)];
        boxB_ = A1 * boxB + T1*ones(1,4)*2^num_down; %Transformed corners of B

        boxR = [1  size(R,2) size(R,2)  1 ;
                1  1           size(R,1)  size(R,1)];
        boxR_ = A2 * boxR + T2*ones(1,4)*2^num_down; %Transformed corners of R

        %Define the x and y entries for the meshgrid based on a grid that
        %can encapsulate R,G, and B
        ur = min([1 boxB_(1,:) boxR_(1,:)]):max([size(G,2) boxB_(1,:) boxR_(1,:)]);
        vr = min([1 boxB_(2,:) boxR_(2,:)]):max([size(G,1) boxB_(2,:) boxR_(2,:)]);

        [u,v] = meshgrid(ur,vr);
        G_ = vl_imwbackward(im2double(G),u,v); %Find G in new grid

        %Find the original x,y coordinates in the original image that map
        %to the coordinates in the full grid.
        H1 = inv(A1);
        uB_ = (H1(1,1) * u + H1(1,2) * v + T1(1));
        vB_ = (H1(2,1) * u + H1(2,2) * v + T1(2));
        B_ = vl_imwbackward(im2double(B),uB_,vB_) ;


        H2 = inv(A2);
        uR_ = (H2(1,1) * u + H2(1,2) * v + T2(1));
        vR_ = (H2(2,1) * u + H2(2,2) * v + T2(2));
        R_ = vl_imwbackward(im2double(R),uR_,vR_) ;

        %Make the final image look good and not have NANs floating around
        B_(isnan(B_)) = 0 ;
        R_(isnan(R_)) = 0 ;
        G_(isnan(G_)) = 0;
        mosaic = zeros(size(G_,1),size(G_,2),3);
        mosaic(:,:,1) = R_;
        mosaic(:,:,2) = G_;
        mosaic(:,:,3) = B_;

        figure();
        imshow(mosaic);
        title('Original');
        %{
%for antiblurring, doesn't work too well
        LEN = 1.9;
THETA = 1;
PSF = fspecial('motion', LEN, THETA);
        wnr1 = deconvwnr(mosaic, PSF, 0);
figure; imshow(wnr1);
title('Restored Image');
        
%}
        shadow = mosaic;
        srgb2lab = makecform('srgb2lab');
        lab2srgb = makecform('lab2srgb');
        shadow_lab = applycform(shadow, srgb2lab); % convert to L*a*b*

        % the values of luminosity can span a range from 0 to 100; scale them
        % to [0 1] range (appropriate for MATLAB(R) intensity images of class double)
        % before applying the three contrast enhancement techniques
        max_luminosity = 100;
        L = shadow_lab(:,:,1)/max_luminosity;

        % replace the luminosity layer with the processed data and then convert
        % the image back to the RGB colorspace
        shadow_imadjust = shadow_lab;
        shadow_imadjust(:,:,1) = imadjust(L)*max_luminosity;
        shadow_imadjust = applycform(shadow_imadjust, lab2srgb);

        shadow_adapthisteq = shadow_lab;
        shadow_adapthisteq(:,:,1) = adapthisteq(L)*max_luminosity;
        shadow_adapthisteq = applycform(shadow_adapthisteq, lab2srgb);

        figure, imshow(shadow_imadjust);
        title('Adjusting contrast');

figure, imshow(shadow_adapthisteq);
title('Gorskii using HDR');
        
    end
    toc();
end

