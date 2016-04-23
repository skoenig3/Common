% Written by Seth konig 2/11/15
% Code pulls pictures from random websites selected by StumbleUpon. Please
% read important notes below.
%
% Important Notes:
% 1) If starting on a new computer, open a web browser in matlab by typing"web"
% and go to Stumbleupon.com. Log in and then select the category "photos".
% You may not need to select photos but at least this should increase the
% probability of finding more images.
% 2) Program runs way faster in 2014b than 2014a because web browser is
% fater.
% 3) If doing another pull make sure the base directory "base_dir"
% or "base_num" is different so that iamges aren't name the same thing.
% 4) Be cautious when pulling, images come from various sources and may
% overlap with some images that we've pulled from Flickr. This probability
% should be low.

% Following lines used to keep all  random popup windows such as .pdf and
% .swf from asking if you want to download file
uicontrol('Visible','Off')
set(0,'DefaultFigureVisible','off');  
close all

img_dir = 'C:\Users\seth.koenig\Documents\';
base_dir = 'SU'; %SU for stumble upon, base directory name  to store images
base_num =2;%starting number for base directory
max_imgs = 1000;%maximum images in a given directory so that it doesn't bog down the OS
% more images will be pulled into a new directory, base_num + 1

number_refreshes = 25000;%number of random websites to visit

minimum_ImageX = 800;%minimum horizontal image size
minimum_ImageY = 600;%minimum vertical image size

current_dir = [img_dir base_dir num2str(base_num) '\'];
if isdir(current_dir);
    error('Directory already exists make a new name for your "base_dir"')
else
    mkdir(current_dir);
end

imgnum = 0;
pull_num = 0;
%pulled_urls = {}; %uncomment if you want to save urls
for rf = 1:number_refreshes
    num_imgs_in_dir =  size(ls(current_dir),1);
    if num_imgs_in_dir >= max_imgs %if filled direcotory, make a new directory to fill
        %save([current_dir 'pulled_urls.mat'],'pulled_urls');%save urls got
        %images from in case, uncomment if you want to save urls
        base_num = base_num+1;
        imgnum = 0;
        pull_num = 0;
        %pulled_urls = {};% uncomment if you want to save urls
        current_dir = [img_dir base_dir num2str(base_num) '\'];
        if isdir(current_dir);
            error('Directory already exists make a new name for your "base_dir"')
        else
            mkdir(current_dir);
        end
    end
    
    try
        [~,hdl] = web('http://www.stumbleupon.com/to/stumble/go/?clientid=4544d41498a10a385d3e4a8a43dfc6b1&client_type=bookmark&version=1.0');
        pause(3)%wait for the website to fully load
        newurl = get(hdl,'CurrentLocation');%stumbleupon will redirect to a new site so read new url
        if isempty(newurl)
            pause(3)
            newurl = get(hdl,'CurrentLocation');%stumbleupon will redirect to a new site so read new url
            if isempty(url)
                continue %taking to long to load go to the next website
            end
        end
            
    catch
        continue
    end
    slashes = strfind(newurl,'/');
    if length(slashes) < 6
       continue%try next url 
    end
    newurl = newurl(slashes(6)+1:end);%the address without the stumble upon stuff
    close(hdl);%close site since may bog down processing
    
    if ~isempty(strfind(lower(newurl),'flickr'))
        % don't want to pull anything from flickr since we already do elsewhere
        continue %continue to the next website
    end
    
    % pulled_urls{pull_num+1} = newurl; %save urls visited to cell array  uncomment if you want to save urls
    pull_num = pull_num+1;
    if ~isempty([strfind(newurl,'.jpg') strfind(newurl,'.jpeg') strfind(newurl,'.bmp') strfind(newurl,'.tif') strfind(newurl,'.png')])
        %url is actually the url for an image; this is not uncommon
        try
            img = imread(['http://' newurl]); %1st 56 are for stumbleupon url
        catch
            try
                img = imread(['https://' newurl]); %1st 56 are for stumbleupon url
            catch
                continue %continue to the next website
            end
        end
        if (size(img,3) ~= 1) && (size(img,1) >= minimum_ImageY) && (size(img,2) >= minimum_ImageX)
            %don't want to pull in images that are obviously gray scale or too
            %small, it's a waste of computer resources.
            imwrite(img,[current_dir base_dir num2str(base_num) '_' num2str(imgnum +1)  '.bmp'],'BMP')
            imgnum = imgnum + 1;
        end
        continue %continue to the next website
    end
    
    try
        s=urlread(['http://' newurl]);
    catch
        try
            s=urlread(['https://' newurl]);
        catch
            continue %to next webpage
        end
    end
    imgind = [strfind(s,'.jpg') strfind(s,'.jpeg') strfind(s,'.bmp') strfind(s,'.tif') strfind(s,'.png')];
    %likely only going to be jpgs but might as well search for the other types
    %in case since this takes only a short period of time
    if ~isempty(imgind) %sometimes only get videso and gifs
        url_length = length(newurl); %get generall www.####.com length
        for id = 1:length(imgind)
            txt = s(imgind(id)-url_length-25:imgind(id)+3);% img type (e.g. jpg) only 3 chars
            http_ind = strfind(txt,'http');
            if isempty(http_ind) %if there is no link probably not a reference to an image
               continue %continue to next potential image
            end
            img_url = txt(http_ind:end);
            if ~isempty(strfind(lower(newurl),'flickr'))
                % don't want to pull anything from flickr since we already do elsewhere
                continue; %continue to the next image
            end
            try
                img = imread(img_url);
                if (size(img,3) ~= 1) && (size(img,1) >= minimum_ImageY) && (size(img,2) >= minimum_ImageX)
                    %don't want to pull in images that are obviously gray scale or too
                    %small, it's a waste of computer resources.
                    imwrite(img,[current_dir base_dir num2str(base_num) '_' num2str(imgnum +1)  '.bmp'],'BMP')
                    imgnum = imgnum + 1;
                end
            catch
                continue %continue to next image
            end
        end
    end
    clc %clear away a bunch of java "Exception" stuff
end