function save_batch_sort_spots_results_in_txt(...
    save_filename,analysis_filelist,ROI_vals,nspots_per_ROI,...
    integrated_Int_per_ROI,ROI_volume)

%save sorting results summary to a tab delimited file 
%(useful for batch results)
%inputs: 

%save_filename: a filename where the results will be saved

%analysis_filelist: a [nimg,nchannels+1] list of files. last column
%corresponds to the masks filenames; nimg is the number of files analyzed,
%nchannels the number of channels analyzed.

%ROI_vals: a cell array that lists all ROI ID values for each image. 
%its size is [nimg,1] where nimg is the number of files analyzed. Each
%entry is an a column array of ID values

%nspots_per_ROI: a cell array that lists the number of spots 
%in each analyzed channel in each ROI in each image. 
%its size is [nimg,nchannels] where nimg is the number of files analyzed 
%and nchannels the number of channels analyzed. 
%Each entry is an a column array of spot numbers. 
%order matches that of the ID values arrays.

%ROI_volume: a cell array that lists the volume encompassed 
%by distinct ROIs for each image. 
%its size is [nimg,1] where nimg is the number of files analyzed. Each
%entry is an a column array of volume values. order matches that of the ID
%values arrays.

%output format
%1 separate sheet per channel analyzed
%each sheet lists the filename for the detected spot and the masks in the first 2
%columns. then an extra column for the number of the FOV
%'vertical' format:
%ROI are listed vertically: one column for ID, one for number of spots, one
%for ROI volume.
%'horizontal' format:
%ROIs are listed horizontally, one row per FOV, each ROI is assigned a
%group of 3 columns: ID, number of spots, volumes

%safety checks
nimg = size(ROI_volume,1);
nchannels = size(nspots_per_ROI,2);
if size(nspots_per_ROI,1) ~= nimg
    dispwin('input error','inconsistent input sizes, cannot save to txt file');
end
if size(ROI_vals,1) ~= nimg
    dispwin('input error','inconsistent input sizes, cannot save to txt file');
end

%prepare FOV IDs and corresponding filenames
FOV_ID = [];
for j=1:size(ROI_vals,1) %loop through FOVs
    FOV_ID = [FOV_ID;j*ones(size(ROI_vals{j,1}))];
end

ROI_ID = cell2mat(ROI_vals(:,1));
ROI_volume = cell2mat(ROI_volume(:,1));


num_spots = [];
integrated_spotInt = [];
channel = [];
filename = [];
mask_filename = [];
for i=1:nchannels
    cur_nspots_per_ROI = cell2mat(nspots_per_ROI(:,i));
    num_spots = [num_spots;...
        cur_nspots_per_ROI];

    cur_integrated_spotInt = cell2mat(integrated_Int_per_ROI(:,i));
    integrated_spotInt = [integrated_spotInt;...
        cur_integrated_spotInt];
    
    channel = [channel;...
        i*ones(size(cur_nspots_per_ROI))];
    
    curfilename = [];
    for j=1:size(analysis_filelist,1)
        curfilename = [curfilename; ...
            repmat(analysis_filelist(j,i),size(ROI_vals{j,1}))];
    end
    
    filename = [filename;...
        curfilename];
    
    curmaskname = [];
    for j=1:size(analysis_filelist,1)
        curmaskname = [curmaskname; ...
            repmat(analysis_filelist(j,end),size(ROI_vals{j,1}))];
    end
    
    mask_filename = [mask_filename;...
        curmaskname];

end

FOV_ID = repmat(FOV_ID,nchannels,1);
ROI_ID = repmat(ROI_ID,nchannels,1);
ROI_volume = repmat(ROI_volume,nchannels,1);

%write data
T = table(FOV_ID,ROI_ID,num_spots,integrated_spotInt,...
    ROI_volume,channel,filename,mask_filename);

writetable(T,save_filename,'Delimiter','\t');

end