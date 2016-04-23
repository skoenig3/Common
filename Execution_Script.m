% Script to run other scripts and email me if error occurs or when script
% is done

dir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\';
mscript = 'BatchRecordingData.m';

try
    run([dir mscript])
    emailme([mscript 'successfully finished running'])
catch
    emailme(['Error running occured while running ' mscript])
end
