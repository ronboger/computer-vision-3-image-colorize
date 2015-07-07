##Colorizing the Prokudin-Gorskii photo collection

Done as a project for JHU Computer Vision, Fall 2014

Developed by Ron Boger and Doran Walsten

I'm choosing to open source this code because i think it's really cool and well worth a run through if you have MATLAB. It colorizes a brilliant Russian guy's experiment with different lenses before color cameras were invented.

A full PDF writeup of the methods used is also in this repo - project1 report.pdf.

Leverages the [VLFeat](http://www.vlfeat.org) Package, a popular open source computer vision library for MATLAB. For installation instructions go [here](http://www.vlfeat.org/install-matlab.html)

To run our code, we have a function called rgb_merge.m that runs everything on a single image including the image enhancements. Simply pass the filename of an image as text to the method, and it will run everything from there and generate the superimposed images. This method will output 3 figures: Original, Contrast Applied, and "HDR mode". 

proj1.m is our wrapper function that runs rgb_merge for all the low-res images and high-res images we liked. These are stored in a folder called ‘images’. Feel free to insert other images you’d like to test into this folder. 

Links to some more high resolution images we used in our project:

-[House w/ trees](http://www.loc.gov/pictures/collection/prok/item/prk2000000093/)

-[House w/ people](http://www.loc.gov/pictures/collection/prok/item/prk2000000096/)

-[Church](http://www.loc.gov/pictures/collection/prok/item/prk2000000036/)

ransac2d.m is our function that runs RANSAC on a pair of images. Feel free to give that a shot as well. In this case, you must pass grayscale images to the method.