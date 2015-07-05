%Doran Walsten, Ron Boger
%Computer Vision, Project 1
%proj1.m - Generate all the images given and found

%Note: We had a folder "images" which contained all of our images

close all;
clear all;
clc;
file_name=dir(strcat('images/'));

 for i=1:length(file_name)
    if strcmp(file_name(i).name(1),'.')==0 %Ignore weird files
        filename = strcat('images/',file_name(i).name);
        Im = rgb_merge(filename);
    end
 end