function [extended_ROI_ind] =  extend_ROI(ROI,extension_size,imageX,imageY)
% extend the ROI by a specified amount in pixels to allow for errors in
% calibration
% written 5/26/2014 by Seth Konig
%

if any(size(ROI) == 1); %assume in index coordinates
    [x,y] = ind2sub([imageY,imageX],ROI);
elseif size(ROI,2) == 2;
    x = ROI(:,1);
    y = ROI(:,2);
else
    x = ROI(1,:);
    y = ROI(2,:);
end  
    
%crude but works
extended = [[x,y];[x+extension_size,y];[x-extension_size,y];[x,y+extension_size];...
    [x,y-extension_size];[x+extension_size,y+extension_size];...
    [x-extension_size,y-extension_size];[x+extension_size,y-extension_size];...
    [x-extension_size,y-extension_size]];

extended(extended < 1) = 1;
extended(extended(:,1) > imageX,1) = imageX;
extended(extended(:,2) > imageY,2) = imageY;

extended_ROI_ind = sub2ind([imageY,imageX],extended(:,2),extended(:,1));
extended_ROI_ind = unique(extended_ROI_ind);