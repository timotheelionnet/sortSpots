function tOut = save_batch_sort_spots_results_as_Matrix(saveFileName,t,prefix,suffix)
nDigits = 2; % number of digits in channel indices used as variable names.
% leading zeros will be used, e.g. if nDigits = 2 :  ch01, ch02, ch03 etc

%% generate a list variable names that includes for each channel its channel index plus files prefix/suffix
nChannels = numel(prefix) - 1;
if (numel(suffix) - 1 ) ~= nChannels
    disp('prefix and suffix should have the same size. Cannot create output matrix');
    return
end

v = t.Properties.VariableNames;
idx = find(ismember(v,'channel'));
if isempty(idx)
    disp('couldn''t find channel in table. Cannot create output matrix');
    return
end

if nChannels ~= max(table2array(t(:,idx)))
    disp('prefix /suffix info doesn''t match channel numbers in table. Cannot create output matrix');
    return
end

channelVars = cell(1,nChannels);
for i=1:nChannels
    nZeros = nDigits - floor(log(i)/log(10)+1);
    zeroString = repmat('0',1,nZeros);
    channelVars{i} = matlab.lang.makeValidName(...
        ['ch',zeroString,num2str(i),'_',prefix{i},'_',suffix{i}]);
end

% create new variable string
v2 = [v(1:idx-1),channelVars,v(idx+1:end)];

% omit variable that stores the file name for each channel
v2 = v2(~ismember(v2,{'fileName','num_spots','integrated_spotInt'}));

% create variable types
v2Types = [repmat({'double'},1,(numel(v2)-1)),{'string'}];
%% compile channel counts into a matrix format

% create an empty table with required variables
tOut = table('Size',[0, numel(v2)],'VariableNames',v2,'variableTypes',v2Types);

% collect a list of unique image (FOV_ID) and ROIs (ROI_ID) IDs in the dataset.
t2 = t(:,~ismember(v,{'fileName','num_spots','channel','integrated_spotInt'}));
r = unique(t2,'rows');

% turning off warnings otherwise we get one every line added to the table
warning('off');

ctr = 0;
for i=1:size(r,1)
    % select data from all channels matching the current image and ROI
    curT = t( (t.FOV_ID == r.FOV_ID(i)) & (t.ROI_ID == r.ROI_ID(i)),: );
    
    % copy the non channel info in their respective columns
    ctr = ctr+1;
    for nVar = 1:numel(r.Properties.VariableNames)
        tOut.(r.Properties.VariableNames{nVar})(ctr) = ...
            t2.(r.Properties.VariableNames{nVar})(i);
    end
    for j=1:nChannels        
        tOut.(channelVars{j})(ctr) = curT.num_spots(curT.channel == j);
    end
end

% warnings back on
warning('on');

%% save matrix 
writetable(tOut,saveFileName,'Delimiter','\t');

end