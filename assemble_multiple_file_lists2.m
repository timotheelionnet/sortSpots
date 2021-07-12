function [fname,basename] = assemble_multiple_file_lists2(listing,prefix,suffix)

numfiles = 0;
basename = cell('');
for i1=1:size(listing{1},1)
    %search for candidates in the channel 1
    [~,basenametmp,~] = fileparts(listing{1}{i1});
    if ~isempty(suffix{1})
        k1 = strfind(basenametmp,suffix{1});
    else
        k1 = length(basenametmp)+1;
    end
    
    if ~isempty(prefix{1})
        l1 = strfind(basenametmp,prefix{1}) ...
            + length(prefix{1});
    else
        l1 = 1;
    end
    basenametmp = basenametmp(l1:k1-1);
    idx(1) = i1;

    %once candidate file is found in channel 1,
    %look into other directories for files with matching basename and the
    %adequate suffix
    find_all_files =1;
    for i = 2:numel(listing)
        flag = 0;
        for i2 = 1:size(listing{i},1)
            [~,name2,~] = fileparts(listing{i}{i2});
            k2 = strfind(name2,basenametmp);
            if isscalar(k2) 
                flag = 1;
                idx(i) = i2;
                break;
            end
        end 
        find_all_files = find_all_files*flag;
    end

    %store file names if all matching names have been found
    if find_all_files == 1
        numfiles = numfiles +1;
        for i = 1:numel(listing)
            fname{numfiles,i} = fullfile(listing{i}{idx(i)});
            basename{numfiles} = basenametmp;
        end
    else
        disp('could not match all file names into sets');
    end

end