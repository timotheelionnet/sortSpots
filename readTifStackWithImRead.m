function [tiff_stack,nSlices] = readTifStackWithImRead(fileName)

tiff_info = imfinfo(fileName); % return tiff structure, one element per image
nSlices = size(tiff_info, 1); % find number of slices/frames

% allocate stack
tiff_stack = zeros(tiff_info(1).Height,...
    tiff_info(1).Width,...
    nSlices); 

if strcmp(tiff_info(1).Format,'png')
    if nSlices > 1
        disp(['Cannot read multi slice png file ',fileName]);
        return
    end
    tiff_stack  = imread(fileName);
    return;
end

% load each successive tiff to tiff_stack
for i = 1 : nSlices
    tiff_stack(:,:,i) = imread(fileName, i);
end



