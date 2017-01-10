function [output1,output2] = remove_nans(input1,input2)
% written by Seth Konig August 19, 2014
%take out the NaNs from both inputs and preserve relative structure between
%both inputs
%
% rechecked for bugs October 19, 2016 SDK

input1(isnan(input2)) = [];
input2(isnan(input2)) = [];
input2(isnan(input1)) = [];
input1(isnan(input1)) = [];

output1=input1;
output2=input2;