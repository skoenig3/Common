% function [] = getflickr(numpics)
% Mike Jutras
% Nathan Killian
% updated 6/19/2012 nk, fixed url names and now grabs hi-res (_b) photos
% last updated 8/20/2013 SK, fixed url names and import as bmp

% updated 4/4/2014 MJJ, changed all instances of "http" to "https" (except
% for "imageind{k} = ['http' imageind{k}(6:end-5) 'b.jpg'];", images themselves still use http), and made minor
% adjustments to account for these changes

% updated 4/10/2014 Yoni started to mess around with things to see if he
% could fix bug causing a stop halfway through running
% Fixed by Seth on 4/16/2014

% updated 1/11/16 added farm2 and added https:// to line 43

% may be a max of 500 per day, 3500 for 7 days
% if photo is already in the folder it will be overwritten

% number of pictures desired
numpics=5000;%at 1750 to current amount of images in folder e.g. 2nd pull set to 3500
%saveDir = 'R:\Buffalo Lab\eblab\Flickr pics\';
saveDir = 'C:\Users\seth.koenig\Documents\MATLAB\ListSQ\FlickrImages\';

last_time = dlmread('\\research.wanprc.org\Research\Buffalo Lab\eblab\Flickr pics\Last_Flickr_Pull.txt');
todays_time = now; %serial date and time

if todays_time-last_time < 6.5 %if it's been less than 7 days don't run
    error(['Pictures were grabbed less than 7 days ago on ' datestr(last_time)])
else %otherwise go ahead and grab images
    l=0;%number of pics grabbed
    m = 0; %number of refreshes
    while (l <= numpics) && (m <= 1000) %just to cap the program from running forever
        m = m + 1;
        s=urlread('https://www.flickr.com/explore/interesting/7days/');% (re)load the site source code
        
        clear siteind
        hind=strfind(s,'h');
        i=1; 
        for k=1:length(hind)
            if ((hind(k)+6)<length(s))
                %https:// added 1/11/16
                if strcmp(s(hind(k):hind(k)+6),'http://') || strcmp(s(hind(k):hind(k)+7),'https://')
                    firstquote=strfind(s(hind(k):end),'"');
                    if ~isempty(firstquote)
                        siteind{i}=s(hind(k):(firstquote(1)+hind(k)-2));
                        i=i+1;
                    end
                end
            end
        end
        
        clear imageind
        i=1;
        for k=1:size(siteind,2)
            %         siteind{k}
            if size(siteind{k},2)>30 %fixme: make generic 1-9
                if strcmp(siteind{k}(1:31),'https://farm6.staticflickr.com/')
                    imageind{i}=siteind{k}(1:64); %63 char limit added 30-Jul-2009 due to error in flickr html source
                    i=i+1;
                elseif strcmp(siteind{k}(1:31),'https://farm8.staticflickr.com/')  %seems to be inactive now june 26,2014
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/15/10
                    i=i+1;
                elseif strcmp(siteind{k}(1:31),'https://farm9.staticflickr.com/')  %seems to be inactive now june 26,2014
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/15/10
                    i=i+1;
                elseif strcmp(siteind{k}(1:31),'https://farm5.staticflickr.com/') %seems to be inactive now june 26,2014
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/15/10
                    i=i+1;
                elseif strcmp(siteind{k}(1:31),'https://farm4.staticflickr.com/')
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/15/10
                    i=i+1;
                elseif strcmp(siteind{k}(1:31),'https://farm3.staticflickr.com/')
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/15/10
                    i=i+1;
                  elseif strcmp(siteind{k}(1:31),'https://farm2.staticflickr.com/')
                    imageind{i}=siteind{k}(1:64); %additional image server added 1/11/11
                    i=i+1;
                end
            end
        end
        
        clear x
        for k=1:length(imageind)
            imageind{k} = ['https' imageind{k}(6:end-5) 'b.jpg'];% b suffix is higher resolution, h appears to be higher res, but it looks like not all photos have an h type
            try
                x{k}=imread(imageind{k});
            catch err
                disp('error')
            end
            %     figure;image(x{k})
        end
        
        for k=1:length(x)
            imtitle=[saveDir imageind{k}(find(double(imageind{k})==47,1,'last')+1:end)];
            if exist(imtitle,'file')~=2
                %             imwrite(x{k},imtitle,'jpg','Bitdepth',12,'Mode','lossless','Quality',100);
                if ~isempty(x{k})
                    imwrite(x{k},[imtitle(1:end-4) '.bmp'],'BMP')
                else
                    disp('error')
                end
            end
            if l==numpics
                break
            end
        end
        l = size(ls(saveDir),1);
        disp(['Refresh Number ' num2str(m) '. ' num2str(l) ' images pulled']);
        if l==numpics
            break
        end
    end
    dlmwrite('\\research.wanprc.org\research\Buffalo Lab\eblab\Flickr pics\Last_Flickr_Pull.txt',todays_time,'precision','%f');
end