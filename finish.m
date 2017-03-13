% FINISHSAV  Save workspace variables
%   Change the name of this file to FINISH.M
%   and put it anywhere on your MATLAB path.
%   When you quit MATLAB this file will be executed.
%   This script saves all the variables in the
%   work space to a MAT-file.

%   Copyright 1984-2000 The MathWorks, Inc.
%   $Revision: 1.4 $  $Date: 2000/06/01 16:19:26 $

home = 'C:\Users\seth.koenig\Documents\MATLAB\';
network = 'R:\Buffalo Lab\Seth\';
disp('Saving workspace data');
save([home 'LastWorkSpace'])
%%
%%---Backup Anything that has been changed in the last 5 days---%
disp('Saving Matlab files to Network...');
dir_not_to_copy = {'generic','IBS522R Fake Data','classificator_1.5',...
    'TL_recording_data','Undergrad_Test','Face Cells','VPC ASL'};
tic
dd = dir(home);
datebuffer=7; %files that have changed in the last # many days to backup
today = datenum(clock);
for d = 1:length(dd);
    if dd(d).isdir;
        if ~strcmpi(dd(d).name(1),'.') %not matlab folders
            if ~any(strcmpi(dir_not_to_copy,dd(d).name)) %don't want to save these to network either
                if ~isdir([network dd(d).name]) %if directory does not exist
                    mkdir([network dd(d).name])
                end
                files = dir([home dd(d).name,'\*.m']);
                for f = 1:length(files);
                    if (today - files(f).datenum) < datebuffer
                        copyfile([home dd(d).name '\' files(f).name],...
                            [network dd(d).name '\' files(f).name],'f')
                        disp(['Copying ' [home dd(d).name '\' files(f).name]])
                    end
                end
            end
        end
    end
end
disp('Files successfully backedup to the network!')
toc
