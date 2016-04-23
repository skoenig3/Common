function tform = get_calibration_fcn(control,input)
% Written by Seth Konig 5/19/20
% Code finds the transformation function that produces the best
% calibration.
%
% Inputs:
%   1) control: known location or calibration points
%   2) input: estimated location of calibration points based on eye data. 
%       a) taken from cortex these will be in mV. Tform will automatically
%       scale/convert this data into units of the control points. 
%       b) input MUST be arranged so that input points correspond to the
%       control points otherwise the transofmraiton will produces something
%       incoherent. 
%  Outputs:
%   1) tform: calibration transfomation function that can be applied to all
%   data

controlx = control(1,:);
controly = control(2,:);

meanx = input(1,:);
meany = input(2,:);

 %must have at least 10 points to use 3rd order polynomial and 15 points to
 %use 4th order polynomial
if length(controlx) < 10
    poly = [];
elseif length(controlx) < 15
    poly = [2 3]; 
else
    poly = [2 3 4];
end

for p = 1:length(poly)
    tform(p) = cp2tform([controlx' controly'], [meanx' meany'],'poly',poly(p));
    tform(p).forward_fcn = tform.inverse_fcn;
end

tform(length(poly)+1) = cp2tform([controlx' controly'], [meanx' meany'],'affine');
tform(length(poly)+1).forward_fcn = tform(length(poly)+1).inverse_fcn;

for p = 1:length(poly)+1
    newx = [];
    newy = [];
    %     figure
    %     hold on
    for i = 1:length(controlx);
        %         plot(controlx(i),controly(i),'r+')
        [x,y] = tformfwd(tform(p),meanx(i),meany(i));
        %         plot(x,y,'*b')
        newx(i) = x;
        newy(i) = y;
    end
    
    MSE(p) = mean(sqrt((newx-controlx).^2 + (newy-controly).^2)); %Mean Squared Error by Transformation Type
end

best_method = find(MSE == min(MSE));

%often affine is fine so use it if MSE is within 20% of best method
if best_method ~= length(MSE);
    if MSE(best_method)*1.2 > MSE(end)
         best_method = length(MSE);
    end
end

if best_method == length(poly)+1
    disp('Best Calibration Method: Affine')
else
    disp(['Best Calibration Method: Polynomial of order ' num2str(best_method+1)])
end

tform = tform(best_method); %only take the function with the best calibration aka least MSE
end