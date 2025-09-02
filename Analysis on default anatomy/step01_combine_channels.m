% 合并之后再brainstorm载入
% channel.mat在D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\data\Group_channels\@intra
%% 
sub_list = {'sub02','sub04','sub08','sub10','sub11','sub13','sub33','sub40'};
project_dir = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\';

%%
for i = 1: length(sub_list)
    path = [project_dir, 'data\Group_channels\',sub_list{i},'\channel.mat'];
    
    if i == 1
        cnew = load(path);
    else
        c_current = load(path);
        fields = fieldnames(c_current.Channel);
        n_before = length(cnew.Channel);
        % Loop through each field and concatenate the values
        for f = 1:length(fields)
            fieldName = fields{f};
            for j = 1:length(c_current.Channel)
                cnew.Channel(n_before+j).(fieldName) = c_current.Channel(j).(fieldName);
            end
        end
    end
end

%%
cnew.Comment = ['SEEG/ECOG (', int2str(length(cnew.Channel)) ,')'];
