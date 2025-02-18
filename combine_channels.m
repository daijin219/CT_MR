%% 
sub_list = {'Comman_template', 'SUBa', 'SUBb', 'SUBc', 'SUBd'};


%%
for i = 1: length(sub_list)
    path = ['D:\SEEG_decode\SEEG_decode_analysis-main\PET_MR\brainstorm_database\MR_CT_Electrode\data\', sub_list{i},'\Implantation\channel.mat'];
    
    if i == 1
        path = ['D:\SEEG_decode\SEEG_decode_analysis-main\PET_MR\brainstorm_database\MR_CT_Electrode\data\', sub_list{i},'\Implantation\channel_240920_1632.mat'];
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

%%
% path = 'D:\SEEG_decode\SEEG_decode_analysis-main\PET_MR\brainstorm_database\MR_CT_Electrode\data\Comman_template\Implantation\channel.mat';

a = load('D:\SEEG_decode\SEEG_decode_analysis-main\PET_MR\channels.mat');
