% Vision Prac Exam
clear all; clc; close all;
%------------------------Part 1--------------------------
%Test displays three shapes on sheet to identify

%Task 1 - Test sheet
% - Create binary image
% - Use gather object function
% - Identify shapes and display shape, colour, size information on test
% sheet
test_img = imread('test_img.jpg');
test_img = imrotate(test_img,270);
[tredC,tgreenC,tblueC] = extract(test_img);
[trb,tred,tgb,tgreen,~,~] = gatherInfo(tredC,tgreenC,tblueC);
allt = [tred;tgreen]; 
alltb = [trb;tgb];

%Extract data from main worksheet
img = imread('img.jpg');
img = imrotate(img,270);
[imRedC,imGreenC,imBlueC] =  extract(img);

%Calculate blobs
[rb,red,gb,green,bb,blue] = gatherInfo(imRedC,imGreenC,imBlueC);

%Automatically calibrate blue circles
bb = calibrate(bb);
sb = size(bb);
for i = 1:sb(1)
    plot_figure(bb(i),'b',true);
end
%Merge red and green shapes into one image
merged = imRedC + imGreenC;
figure(); imshow(merged);
allshapes = [red;green];
allblobs = [rb;gb];
sa = size(allshapes);
st = size(allt);
H = Homography(bb);
coords = get_coordinates(allblobs,H);

%Find test shapes in main worksheet
 for i = 1: sa(1)
    for j = 1 : st(1)
       if strcmp(allt(j,2),allshapes(i,2)) && strcmp(allt(j,3),allshapes(i,3)) && strcmp(allt(j,4),allshapes(i,4))
           allt{j,5} = coords(i,1);
           allt{j,6} = coords(i,2);
       end
    end
 end
 
 %Seperate into inital and destination shapes
 [minx,maxx,~,~] = getminmax(alltb);
 location = {};
 destination = {};
 w3 = (maxx.uc - minx.uc) / 2;
 for i = 1 : size(alltb,1)
     t = alltb(i);
     j = allt(i,:);
     if t.uc < w3
         destination = [destination;j];
     else
        location = [location;j]; 
     end
 end
lcoords = {};
dcoords = {};
for i = 1 : 3
   lc = [location(i,5),location(i,6)];
   dc = [destination(i,5),destination(i,6)];
   lcoords = [lcoords;lc];
   dcoords = [dcoords;dc];
end
%Display coordinates and pause
disp(location);
disp(destination);
pause();
runClaw(lcoords,dcoords);

function [red,green,blue] = extract(img)
    imRed = img(:,:,1);
    imGreen = img(:,:,2);
    imBlue = img(:,:,3);
    imRed = normalize_and_correct(imRed);
    imGreen = normalize_and_correct(imGreen);
    imBlue = normalize_and_correct(imBlue);
    
    red = chromatical(imRed,imGreen,imBlue);
    blue = chromatical(imBlue,imGreen,imRed);
    green = chromatical(imGreen,imRed,imBlue);
end

function [rb,red,gb,green,bb,blue] = gatherInfo(redIn,greenIn,blueIn)
    [rb,red] = gatherObjInfo(redIn,'Red');
    [gb,green] = gatherObjInfo(greenIn,'Green');
    [bb,blue] = gatherObjInfo(blueIn,'Blue');
end

% Normalizes and then applies Gamma Correction
% @ret - Returns the normalized and Gamma Corrected img
function ret = normalize_and_correct(input)
    Gamma = 2.25;
    normalized = double(input)/255;
    ret = normalized .^ Gamma;
end

% Extracts the chromatic information from an img
% @source - The colour you want to extract
% @alt1 - A colour not the same as @source or @alt2
% @alt2 - A color not the same as @source or @alt1
% @Ret - Returns an img with only the @source remaining
function ret = chromatical(source,alt1, alt2)
ret = (source ./ (source + alt1 + alt2)) > 0.5;
end

% Gathers shape information from an img
% @img - The img you want to gather obj information from
% @colour - The colour to be applied to the obj information
% @ret - Returns a vector containing the obj information of
%        all shapes in the img
function [ret,out] = gatherObjInfo(img,colour)
    ret = {};
    out = {};
    min_threshold = 10000;
    max_threshold = 100000;
    sl_threshold = 39000;
    blobs = iblobs(img,'boundary','touch',0);
    counter = 0;
    for it = 1:length(blobs)
        area = blobs(it).area;
        if area  < min_threshold
            continue;
        elseif area > max_threshold
            continue;
        elseif area < sl_threshold
            size = 'Small';
        elseif area > sl_threshold
            size = 'Large';
        end
        counter = counter + 1;
        if blobs(it).circularity > 0.9
            shape = 'Circle';
        elseif blobs(it).circularity > 0.7
            shape = 'Square';
        elseif blobs(it).circularity > 0.55
            shape = 'Triangle';
        else
            shape = 'Undefined';
        end    
        obj = {counter,size,colour,shape};
        out = [out; obj];
        ret = [ret; blobs(it)];
       
    end
end

% 
function plot_figure(obj,colour,box)
    for i = 1:length(obj)
        if (box == true)
         obj(i).plot_box(colour);
        end
        obj(i).plot('r*');
    end
end

function H = Homography(obj)
    Pb = zeros(2,size(obj,1));
    Q = [ 20 560; 182.5 560; 345 560;...
        20 290; 182.5 290; 345 290;  ...
        20 20; 182.5 20; 345 20; ];
    for i = 1:size(obj,1)
        Pb(1,i) = obj(i).uc;
        Pb(2,i) = obj(i).vc;
    end
    H = homography(Pb,Q');      
end

%Get minimum and maximum coordinates to calibrate blue circles with
function [minx,maxx,miny,maxy] = getminmax(obj)
    minx = obj(1);
    miny = obj(1);
    maxx = obj(1);
    maxy = obj(1);
    for i = 2 : size(obj,1)
        t = obj(i);
        if minx.uc > t.uc
            minx = t;
        elseif maxx.uc < t.uc
            maxx = t;
        end
        if miny.vc > t.vc
            miny = t;
        elseif maxy.vc < t.vc
            maxy = t;
        end
    end
end

%Calibrate homography with blue circle coordinates
function ret = calibrate(obj)
    ret = obj;
    [minx,maxx,miny,maxy] = getminmax(obj);
     w3 = (maxx.uc - minx.uc) / 3;
     y3 = (maxy.vc - miny.vc) / 3;
    for i = 1 : size(obj,1)
     t = obj(i);
     if t.uc < w3
        if t.vc < y3
            ret(1) = t;
        elseif t.vc > y3 && t.vc < y3 * 2
            ret(4) = t;
        else
            ret(7) = t;
        end
     elseif t.uc > w3 && t.uc < w3 * 2
         if t.vc < y3
            ret(2) = t;
        elseif t.vc > y3 && t.vc < y3 * 2
            ret(5) = t;
        else
            ret(8) = t;
        end    
     else
        if t.vc < y3
            ret(3) = t;
        elseif t.vc > y3 && t.vc < y3 * 2
            ret(6) = t;
        else
            ret(9) = t;
        end            
     end
    end
end

function coord = get_coordinates(obj,H)
    coord = zeros(size(obj,1),2);
    for i=1:size(obj,1)
        t = obj(i);
        p = [t.uc t.vc];
        q = homtrans(H,p');
        coord(i,:) = q;
    end
end
