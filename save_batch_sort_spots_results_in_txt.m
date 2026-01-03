function T = save_batch_sort_spots_results_in_txt(...
    saveFileName,analysisFileList,RoiVals,nSpotsPerRoi,...
    integratedIntPerRoi,maxIntPerRoi,ROI_Volume)

%save sorting results summary to a tab delimited file 
%(useful for batch results)
%inputs: 

%saveFileName: a filename where the results will be saved

%analysisFileList: a [nimg,nchannels+1] list of files. last column
%corresponds to the masks filenames; nimg is the number of files analyzed,
%nchannels the number of channels analyzed.

%RoiVals: a cell array that lists all ROI ID values for each image. 
%its size is [nimg,1] where nimg is the number of files analyzed. Each
%entry is an a column array of ID values

%nSpotsPerRoi: a cell array that lists the number of spots 
%in each analyzed channel in each ROI in each image. 
%its size is [nimg,nchannels] where nimg is the number of files analyzed 
%and nchannels the number of channels analyzed. 
%Each entry is an a column array of spot numbers. 
%order matches that of the ID values arrays.

% integratedIntPerRoi: cell array that lists the sum of the intensities of
% all the spots in each analyzed channel in each ROI in each image. 
%its size is [nimg,nchannels] where nimg is the number of files analyzed 
%and nchannels the number of channels analyzed. 
%Each entry is an a column array of spot numbers. 
%order matches that of the ID values arrays.

% maxIntPerRoi same as integratedIntPerRoi, except it stores the max
% intensity of all the spots in the ROI.

%RoiVolume: a cell array that lists the volume encompassed 
%by distinct ROIs for each image. 
%its size is [nimg,1] where nimg is the number of files analyzed. Each
%entry is an a column array of volume values. order matches that of the ID
%values arrays.

%output format
%1 separate sheet per channel analyzed
%each sheet lists the filename for the detected spot and the masks in the first 2
%columns. then an extra column for the number of the FOV
%'vertical' format:
%ROI are listed vertically: one column for ID, one for number of spots, o
% one for integrated intensity, one for max intensity,
% onefor ROI volume, one for channel, one for fileName, one for maskFileName.
%'horizontal' format:
%ROIs are listed horizontally, one row per FOV, each ROI is assigned a
%group of 3 columns: ID, number of spots, volumes

%safety checks
nimg = size(ROI_Volume,1);
nchannels = size(nSpotsPerRoi,2);
if size(nSpotsPerRoi,1) ~= nimg
    dispwin('input error','inconsistent input sizes, cannot save to txt file');
end
if size(RoiVals,1) ~= nimg
    dispwin('input error','inconsistent input sizes, cannot save to txt file');
end

%prepare FOV IDs and corresponding filenames
FOV_ID = [];
for j=1:size(RoiVals,1) %loop through FOVs
    FOV_ID = [FOV_ID;j*ones(size(RoiVals{j,1}))];
end

ROI_ID = cell2mat(RoiVals(:,1));
ROI_Volume = cell2mat(ROI_Volume(:,1));

num_spots = [];
integrated_spotInt = [];
max_spotInt = [];
channel = [];
fileName = [];
maskFileName = [];
for i=1:nchannels
    curNSpotsPerRoi = cell2mat(nSpotsPerRoi(:,i));
    num_spots = [num_spots;...
        curNSpotsPerRoi];

    curIntegratedSpotInt = cell2mat(integratedIntPerRoi(:,i));
    integrated_spotInt = [integrated_spotInt;...
        curIntegratedSpotInt];
    
    curMaxSpotInt = cell2mat(maxIntPerRoi(:,i));
    max_spotInt = [max_spotInt;...
        curMaxSpotInt];
    
    channel = [channel;...
        i*ones(size(curNSpotsPerRoi))];
    
    curFileName = [];
    for j=1:size(analysisFileList,1)
        curFileName = [curFileName; ...
            repmat(analysisFileList(j,i),size(RoiVals{j,1}))];
    end
    
    fileName = [fileName;...
        curFileName];
    
    curMaskName = [];
    for j=1:size(analysisFileList,1)
        curMaskName = [curMaskName; ...
            repmat(analysisFileList(j,end),size(RoiVals{j,1}))];
    end
    
    maskFileName = [maskFileName;...
        curMaskName];

end

FOV_ID = repmat(FOV_ID,nchannels,1);
ROI_ID = repmat(ROI_ID,nchannels,1);
ROI_Volume = repmat(ROI_Volume,nchannels,1);


%write data
T = table(FOV_ID,ROI_ID,num_spots,integrated_spotInt,max_spotInt,...
    ROI_Volume,channel,fileName,maskFileName);

writetable(T,saveFileName,'Delimiter','\t');

end