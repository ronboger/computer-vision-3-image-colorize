function [ A, T, totalnumber] = ransac2d( image1, image2, iter, thr )
%ransac2d takes in feature points from 2 images and returns an Affine
%transformation
%iter - Number of iterations to run
%thr - The error threshold for an inlier, euclidean distance between points


%Find features
[f1, d1] = vl_sift(image1);
[f2, d2] = vl_sift(image2);

%x, y coordinates for every image match
allcoord1 = f1(1:2,:);
allcoord2 = f2(1:2,:);

%Threshold on the location of features: Don't want them to close to edge
goodrows1 = (f1(1,:) < 0.97*size(image1,2)).*(f1(1,:) > 0.03*size(image1,2));
goodcolumns1 = (f1(2,:) < 0.97*size(image1,1)).*(f1(2,:) > 0.03*size(image1,1));
crit1 = find(goodrows1.*goodcolumns1);
coord1 = allcoord1(:,crit1);

goodrows2 = (f2(1,:) < 0.97*size(image2,2)).*(f2(1,:) > 0.03*size(image2,2));
goodcolumns2 = (f2(2,:) < 0.97*size(image2,1)).*(f2(2,:) > 0.03*size(image2,1));
crit2 = find(goodrows2.*goodcolumns2);
coord2 = allcoord2(:,crit2);

d1 = d1(:,crit1);
d2 = d2(:,crit2);

%Find matches
[matches, scores] = vl_ubcmatch(d1, d2,1.75); %THRESHOLD #1 - Matching

%overall x,y coordinates for each match, used for ease of access later
cor1 = coord1(:, matches(1,:));
cor2 = coord2(:, matches(2,:));

data = cell(iter, 2); %Store A,T,best correspondence
in_num = zeros(iter, 1); %Store the number of inliers


for k = 1:iter
    index1 = matches(:, max(1,round(rand * length(matches))));%Pair #1
    index2 = matches(:, max(1,round(rand * length(matches))));%Pair #2
    
    %for pair 1, find image coordinates
    coord11 = coord1(:, index1(1));
    coord12 = coord2(:, index1(2));
    
    %for pair 2, find image coordinates
    coord21 = coord1(:, index2(1));
    coord22 = coord2(:, index2(2));
    
    
    % A = YX^T(XX^T)
    % t= y_avg - Ax_avg
    %treating 2nd image as transformed image of first
    Y = [coord12, coord22];
    X = [coord11, coord21];
    
    A_tmp = Y*pinv(X);
    T_tmp = (coord22 + coord12)./2 - A_tmp*(coord21 + coord11)./2;
    
    error = zeros(1,length(cor1));
    for i = 1:length(cor1)
        error(1,i) = norm(cor2(:,i) - A_tmp*cor1(:,i) - T_tmp);
    end
    
    %Find #inliers
    inliers = find(error < thr);
    numInliers = length(inliers);
    
    data{k, 1} = A_tmp;
    data{k, 2} = T_tmp;
    in_num(k) = numInliers;
   
end

largest_innum = find(in_num == max(in_num));
A = data{largest_innum, 1};
T = data{largest_innum, 2};
totalnumber = in_num(largest_innum(1));

