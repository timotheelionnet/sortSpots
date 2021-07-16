function [fList,nSpotsPerRoi,roiVals,integratedIntPerRoi,roiVolume] = sortSpots()

%input one to three spot detection results files, plus one image that
%contains masks

%outputs in a folder chosen by the user the spots with an extra column that
%corresponds to the object the spot belongs to
%also outputs a summary file that collects the statistics (number of spots
%per object), as well as the source of the data.

%version 2.0: changed file management to work aorund the Mac OS issue.
%version 3.0: ensured that empty loc files would not give an error. Ensured
%that background spots were discarded from summary file if option selected.
%version 6.0: added a 2D/3D option to select which column is taken into
%account for the intensity quantification.

%% set matlab path to include necessary subfunctions
%with platform dependent path names

%Launch_from = 'cluster';
%Launch_from = 'NYUdesktop';
Launch_from = 'LabDesktop';

switch Launch_from
    case 'cluster'
        code_rootname = '/groups/transimcon/home/';
    case 'desktop'
        code_rootname = '/Volumes/';
    case 'NYUdesktop'
        code_rootname = '/Users/lionnt01/Dropbox (HHMI)/MatlabCode/'; 
    case 'LabDesktop'
        code_rootname = 'Z:\lionnt01lab\lionnt01labspace\MatlabCode\';
end

%% add dependencies to the path
% addpath(['..',filesep,'uipickfiles']);
% addpath(['..',filesep,'useful']);
% addpath(['..',filesep,'LCSubstr']);
%% set mode
%mode: 
%one ROI (expurge the spots outside of the ROI)
%multiple ROIs (adds one column that stores the ROI #)
params = set_sorting_mode();
if strcmp(params.mode,'cancel'), return; end

%% enter filenames and paths
%add current folder to the path if not already
startFolder = pwd;
pathCell = regexp(path, pathsep, 'split');
if ispc  % Windows is not case-sensitive
  onPath = any(strcmpi(startFolder, pathCell));
else
  onPath = any(strcmp(startFolder, pathCell));
end

if ~onPath
    disp('Temporarily updating path w current folder...');
    addpath(pwd);
else
    disp('No need to update path');
end

hardcode_paths = 0;
if hardcode_paths
    %hardcode file paths here if that's what you're into
    locFileName{1} = ...
        '<enter here full path to first detection result from channel 1>';
    dirName{1} = fileparts(locFileName{1});
    nChannels = 1;
    maskFileName = '<enter here full path to first mask image>';
    dirName{nChannels+1} = fileparts(maskFileName);
    outDir = ...
        '<enter here full path to where you want your results saved>';
        
else 
    %GUI-based file paths input
    allChannelsFilled = 0;
    nChannels = 0;
    defaultLocExt = {'*','all files'};
    while ~allChannelsFilled
        if nChannels >=1
            cd(dirName{1});
        end
        curFileName = uipickfiles('Prompt',...
            ['Load First Detection result for Channel ',num2str(nChannels+1)],...
            'Type',defaultLocExt,...
            'Output','cell');
        if ~isa(curFileName,'cell')
            allChannelsFilled = 1;
        else
            if isempty(curFileName)
                allChannelsFilled = 1;
            else
                nChannels = nChannels +1;
                locFileName{nChannels} = curFileName{1};
                dirName{nChannels} = fileparts(curFileName{1});
            end
        end
    end
    
    if allChannelsFilled && (nChannels == 0)
        disp('No Channels to process, quitting.');
        return
    end
    
    % enter path to first mask image
    maskFileName = uipickfiles('Prompt',...
        'Load First Mask image',...
        'Type',{ '*.tif*' ,'TIF file'},...
        'FilterSpec',dirName{1},'Output','cell');
    if ~isa(maskFileName,'cell')
        return
    else
        maskFileName = maskFileName{1};
        dirName{nChannels+1} = fileparts(maskFileName);
    end

    % enter path to output dir where results are saved
    outDir = uipickfiles('Prompt',...
        'Enter Output Folder',...
        'FilterSpec',dirName{1},'Output','cell');

    if ~isa(outDir,'cell')
        return
    else
        outDir = outDir{1};
    end
end

%% assemble lists of file names
fList = cell('');

if params.BatchMode == 1
    % extract common root in the file names (basename) and 
    % variable, channel-specific suffix (suffix)
    
    % combine loc file names and mask file name into one list
    all_names = [locFileName,maskFileName];
    
    % extract prefix/suffix specific to individual channels
    [~,~, prefix,suffix,ext] = ...
        find_basename_and_extension2(all_names);
    
    % within the parent folder, collect all file names that follow each channel pattern 
    for i=1:nChannels+1
        listing{i} = get_clean_file_list(...
            dirName{i},{prefix{i},ext{i},suffix{i}},{''},0,0);
    end
    
    % match file names sharing the same base across channels
    fList = assemble_multiple_file_lists2(listing,prefix,suffix)
    prefix
    suffix
    disp(['Found ',num2str(size(fList,1)),' files']);
else
    for i=1:nChannels
        fList{1,i} = locFileName{i};
    end
    fList{1,nChannels+1} = maskFileName;
    disp('Loading files');
end
       
%% sort spots
for i=1:size(fList,1)
    %load mask image
    disp(['Treating File: ',fList{i,nChannels+1}]);
    mask = timtiffread(fList{i,nChannels+1});
    
    %merge all non backgound ROIs into one if option has been selected
    roiLevels = unique(mask(:));
    roiVals{i,1} = roiLevels;
    if params.combineROIs    
        if numel(roiLevels >1)
            mask = (mask> min(roiLevels))*255;
            roiVals{i,1} = [0;255];
        end
    end
    
    %remove the background ROI (defined as minimum ID value) if mode is selected
    if strcmp(params.mode,'discard bg')
        roiVals{i,1} = roiVals{i,1}(roiVals{i,1} ~=min(roiVals{i,1}));    
    end  
    
    % number of dimensions in the mask: 2 for mask image (or projection), 3
    % for stack
    maskDims = ndims(mask);
    
    for j = 1:nChannels
        %load detected spots
        [spots,header] = readLocFile(fList{i,j});
        
        if isempty(spots)
            spots2 = spots;
        else
            
            %generating the array of spots (spots2) with an additional column containing the
            %mask value
            [nr,nc] = size(spots);
            spots2 = zeros(nr,nc+1);
            spots2(1:nr,1:nc) = spots;
            spots(:,1:maskDims) = ceil(spots(:,1:maskDims));

            %making sure the spots are all within the mask image
            spots(:,1) = min(max(spots(:,1),1),size(mask,1));
            spots(:,2) = min(max(spots(:,2),1),size(mask,2));
            if maskDims == 3
                spots(:,3) = min(max(spots(:,3),1),size(mask,3));
            end

            %get linear indices of positions
            if maskDims ==3
                linidx = sub2ind(size(mask),spots(:,1),spots(:,2),spots(:,3));
            elseif maskDims == 2
                linidx = sub2ind(size(mask),spots(:,1),spots(:,2));
            end
        
            %add mask value in extra column
            spots2(:,nc+1) = mask(linidx);

            %sorting the spots by ROI value
            spots2 = sortrows(spots2, nc+1);

            %excluding background spots if the remove background mode is selected
            if strcmp(params.mode,'discard bg')
                spots2 = spots2(spots2(:,nc+1) ~= min( mask(:) ),:);
            end
        end
        
        %saving the sorted spot list
        [~,fnameNoExt] = fileparts(fList{i,j});
        if isempty(header)
            fout = fullfile(outDir,[fnameNoExt,'_mask_sorted.loc3']);
            save(fout,'spots2','-ascii');
        else
            fout = fullfile(outDir,[fnameNoExt,'_mask_sorted.loc4']);
            header = [header,'RoiID'];
            if isempty(spots2)
                t = table('Size',[0, numel(header)],'VariableNames',header,...
                    'variableTypes',repmat({'double'},1,numel(header)));
            else
                t = array2table(spots2,'VariableNames',header);
            end
            writetable(t,fout,'Delimiter','\t','FileType','text');
        end
        
        %generating the file that holds the stats
        roiVals{i,j} = roiVals{i,1}; %replicate mask ROI identities
        nRois = numel(roiVals{i,j});

        NL = sprintf('\r\n');
        summaryFilename = fullfile(outDir,[fnameNoExt,'_mask.sum']);

        fid1 = fopen(summaryFilename,'w');

        str = ['Detection file: ',fList{i,j},NL,...
            'Mask File: ', fList{i,nChannels+1},NL,];

        fprintf(fid1,'%s\r\n',str);

        if strcmp(params.mode,'discard bg')
            strmode = ['Mode: discard background spots',NL];
        else
            strmode = ['Mode: retain background spots',NL];
        end 

        str = ['Total Number of Spots in Image: ',num2str(size(spots,1)) ];
        fprintf(fid1,'%s\r\n',strmode,str);
        integratedIntPerRoi{i,j} = zeros(nRois,1);
        nSpotsPerRoi{i,j} = zeros(nRois,1);
        roiVolume{i,j} = zeros(nRois,1);
        if isempty(spots2)
            for k = 1:nRois
                nSpotsInCurrentRoi = 0;
                integratedIntPerRoi{i,j}(k,1) = 0;
                nSpotsPerRoi{i,j}(k,1) = 0;
                curRoiVolume = sum( mask(:) == roiVals{i,j}(k,1) );
                roiVolume{i,j}(k,1) = curRoiVolume;
                str = ['ROI value: ',num2str(roiVals{i,j}(k,1)),'; ',...
                    num2str(nSpotsInCurrentRoi),...
                    ' spots detected; ROI volume: ',...
                    num2str(curRoiVolume),' voxels'];
                fprintf(fid1,'%s\r\n',str);
            end
        else
            for k = 1:nRois
                nSpotsInCurrentRoi = ...
                    sum( spots2(:,nc+1) == roiVals{i,j}(k,1) );
                integratedIntPerRoi{i,j}(k,1) = ...
                    sum( spots2( spots2(:,nc+1) == ...
                    roiVals{i,j}(k,1),params.ndims+1 ) );
                nSpotsPerRoi{i,j}(k,1) = nSpotsInCurrentRoi;
                curRoiVolume = sum( mask(:) == roiVals{i,j}(k,1) );
                roiVolume{i,j}(k,1) = curRoiVolume;

                str = ['ROI value: ',num2str(roiVals{i,j}(k,1)),'; ',...
                    num2str(nSpotsInCurrentRoi),...
                    ' spots detected; ROI volume: ',...
                    num2str(curRoiVolume),' voxels'];
                fprintf(fid1,'%s\r\n',str);
            end
        end  
        fclose(fid1);
    end
end

%save global stats to text file (legacy format, include all names of files used for each channel)
saveFileName = fullfile(outDir,'sortSpotsStats.txt');

T = save_batch_sort_spots_results_in_txt(saveFileName,fList,roiVals,...
    nSpotsPerRoi,integratedIntPerRoi,roiVolume);

% save as a cell expression matrix (easier to use in downstream applications)
saveFileName = fullfile(outDir,'sortSpotsMatrix.txt');

% dummy prefix/suffix if single file mode.
if params.BatchMode ~= 1
    prefix = repmat({''},1,nChannels+1);
    suffix = repmat({''},1,nChannels+1);
end
save_batch_sort_spots_results_as_Matrix(saveFileName,T,prefix,suffix);

% return current dir and path to its previous state if needed
if ~onPath
    disp('returning path to initial state');
    rmpath(startFolder);
end
cd(startFolder);
end

function params = set_sorting_mode()

%% setting up the figure, panels and buttons
    fh = figure(...
                  'Units','characters',...
                  'MenuBar','none',...
                  'Toolbar','none',...
                  'Name','Spot Sorting Mode',...
                  'NumberTitle','off',...
                  'Position',[50 20 80 24],...
                  'Visible','off'); 

    %radio button group to select the type of data input          
    hsel_mode = uibuttongroup('Units','characters',...
        'Position',[12.5 18 55 5.5]);
        uicontrol('Style','Radio','Units','characters',...
            'String','Discard background spots',...
            'Tag','discard bg',...
            'Position',[1 3 50 2],'parent',hsel_mode);
        uicontrol('Style','Radio','Units','characters',...
            'String','Retain background spots',...
            'Tag','keep bg',...
            'Position',[1 0.8 50 2],'parent',hsel_mode);
    
    hcombineROIs = uicontrol('Style','Radio','Units','characters',...
            'String','Combine spots from non-background ROIs',...
            'Tag','combineROIs',...
            'Position',[12.5 15 55 2],'parent',fh);  
        
    hBatchMode = uicontrol('Style','Radio','Units','characters',...
            'String','Batch Mode',...
            'Tag','BatchMode',...
            'Position',[12.5 12 55 2],'parent',fh);
    
    %radio button group to select the dimensions of the loc data input          
    hdim = uibuttongroup('Units','characters',...
        'Title','Dimensions of loc data files',...
        'Position',[12.5 5 55 5.5]);
    uicontrol('Style','Radio','Units','characters',...
        'String','2D',...
        'Tag','2D',...
        'Position',[1 3 50 2],'parent',hdim);
    uicontrol('Style','Radio','Units','characters',...
        'String','3D',...
        'Tag','3D',...
        'Position',[1 0.8 50 2],'parent',hdim);
        
    % set defaults    
    set(hcombineROIs,'Value',0); 
    set(hBatchMode,'Value',1); 
    set(hsel_mode,'Visible','on');           
    set(fh,'Visible','on');
    
    %next button
    hnext = uicontrol('Parent',fh,'Units','characters',...
                        'Style','pushbutton',...
                        'String','next',...
                        'Position',[47.5,0.5,20,2]);
    %cancel button
    hcancel = uicontrol('Parent',fh,'Units','characters',...
                        'Style','pushbutton',...
                        'String','cancel',...
                        'Position',[12.5,0.5,20,2]);

    set(hnext,'Callback',{@get_params,fh,hsel_mode});                
    set(hcancel,'Callback',{@cancel,fh});                

%% nested callback function
    function get_params(src,eventdata,fh,hsel_mode)
        
        xtag = get(get(hsel_mode,'SelectedObject'), 'Tag');
        if strcmp(xtag,'discard bg')
            params.mode = 'discard bg';            
        elseif strcmp(xtag,'keep bg')
            params.mode = 'keep bg';    
        end
        
        xtag = get(hcombineROIs,'Value');
        if xtag == 1
            params.combineROIs = 1;            
        else
            params.combineROIs = 0;     
        end
        
        xtag = get(hBatchMode,'Value');
        if xtag == 1
            params.BatchMode = 1;            
        else
            params.BatchMode = 0;     
        end
        
        xtag = get(get(hdim,'SelectedObject'), 'Tag');
        if strcmp(xtag,'2D')
            params.ndims = 2;            
        elseif strcmp(xtag,'3D')
            params.ndims = 3;    
        end
        
        clear('nt');
        uiresume;
    end
    
%% nested callback function
    function cancel(src,eventdata,fh)
        uiresume;
        mode = 'cancel';
    end
    
    %% housepkeeping
    uiwait;
    close(fh);
    
    return
    
    
    
end




