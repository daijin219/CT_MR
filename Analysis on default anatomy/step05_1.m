%% 计算距离矩阵
% 载入 channel.mat
load('D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\data\Group_channels\@intra\channel.mat');   % 里面应包含变量 Channel

% 提取所有电极位置 (n 个电极，每个是 3D 坐标)
n = length(Channel);
coords = zeros(n,3);
for i = 1:n
    % Channel(i).Loc 是 3x1 向量
    coords(i,:) = Channel(i).Loc(:)';
end

% 计算两两距离矩阵
D = squareform(pdist(coords));   % 用 pdist 和 squareform 一行搞定

% 显示或保存结果
disp(D);

%% 阈值计算
% 找出距离小于阈值的通道对
threshold = 0.002;
pairs = {};
for i = 1:n
    for j = i+1:n   % 只考虑上三角，避免重复
        if D(i,j) < threshold
            pairs{end+1,1} = Channel(i).Name;
            pairs{end,2}   = Channel(j).Name;
            pairs{end,3}   = D(i,j);   % 可选，保存距离
        end
    end
end

% 显示结果
disp('Contact pairs with distance < 0.002:');
disp(pairs);