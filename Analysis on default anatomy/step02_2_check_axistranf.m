%% load channel
root_dir = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\';
ID = 10;
path_channel = ['data\Group_channels\sub', num2str(ID, '%02d'), '\channel.mat'];
% path_anat = '\anat\Comman_template\tess_innerskull_spm_2562V.mat';
% Load the channel file
channelData = load([root_dir, path_channel]);
% Access the Channel structure
Channels = channelData.Channel;
% volatlas
atlas_dir    = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\anat\@default_subject';  % <--- EDIT
atlas_file = fullfile(atlas_dir,'subjectimage_neuromorphometrics_volatlas.mat');
Mri = load(atlas_file);
%% Extract Electrode Positions and Labels
% Initialize arrays for positions and labels
positions = [];
labels = {};
% Loop through each channel to extract information
for i = 1:length(Channels)
    vox = cs_convert(Mri, 'scs', 'voxel', Channels(i).Loc);
    vox = round(vox);
    positions = [positions; vox];
    labels{end+1} = Channels(i).Name;

end

%% Load the 
Cube = Mri.Cube;
Labels = Mri.Labels;


%% plot
%% ------ brain ------
% 交互式3D可视化
figure;

% 为每个体素查找对应的颜色
colors = zeros(size(Cube,1)*size(Cube,2)*size(Cube,3), 3);
coords = zeros(size(Cube,1)*size(Cube,2)*size(Cube,3), 3);
count_idx = 0;
for i=1:size(Cube, 1)
    for j = 1:size(Cube, 2)
        for k = 1:size(Cube, 3)
            count_idx = count_idx + 1;
            index = find([Labels{:,1}] == Cube(i,j,k));
            colors(count_idx, :) = Labels{index,3};
            coords(count_idx, 1) = i;
            coords(count_idx, 2) = j;
            coords(count_idx, 3) = k;
        end
    end
end

% 创建3D散点图
% brain volatlas
scatter3(coords(:,1), coords(:,2), coords(:,3),...
         10, colors, 'filled','MarkerFaceAlpha', 0.05, 'MarkerEdgeAlpha', 0);
hold;
% electrode contact
scatter3(positions(:,1), positions(:,2), positions(:,3), 'filled','MarkerFaceColor','k');
% 设置坐标轴标签和标题
xlabel('i (voxel, Left→Right)');
ylabel('j (voxel, Posterior→Anterior)');
zlabel('k (voxel, Inferior→Superior)');
title('3D体数据交互式可视化');
axis equal;
grid on;



% 设置视角
view(3);
rotate3d on; % 启用交互式旋转