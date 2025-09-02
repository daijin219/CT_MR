%% === USER PATHS (EDIT THESE) ===
channel_file = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\data\Group_channels\@intra\channel.mat';    % projected channel file
pial_file    = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\anat\@default_subject\tess_head.mat';   % pial surface (cortex)

out_csv      = 'D:\SLEEP_PROJECT\MR_CT\Analysis_Code\contact_depth_from_cortex.csv';

%% --- Load data ---
S  = load(channel_file);     % -> S.Channel
Pi = load(pial_file);        % -> Pi.Vertices

Channel = S.Channel;

%% --- Extract coordinates (convert meters -> mm if needed) ---
names = strings(numel(Channel),1);
P_mm  = nan(numel(Channel),3);
for k = 1:numel(Channel)
    names(k) = string(Channel(k).Name);
    if ~isempty(Channel(k).Loc)
        v = Channel(k).Loc(:,1)';     % SCS, usually in meters
        if max(abs(v)) <= 1           % convert m -> mm if small values
            v = v*1000;
        end
        P_mm(k,:) = v;
    end
end
keep  = all(isfinite(P_mm),2);
P_mm  = P_mm(keep,:); 
names = names(keep);

%% --- Normalize surface units to mm ---
V_pi = Pi.Vertices;
% V_pi = V_pi(V_pi(:, 1)<=0.105, :); % 删除面部点1（这个阈值不是很合适）

% 删除面部点： 定义两点（在 XZ 平面上）
x1 = 0.1;   z1 = 0.05;
x2 = 0.06;  z2 = -0.1;
% 构造3D点
P1 = [x1, 0, z1];
P2 = [x2, 0, z2];
% 向Y方向延展，所以第二个方向向量为Y轴
v1 = P2 - P1;             % 向量1：从P1到P2
v2 = [0, 1, 0];           % 向量2：Y方向
% 计算平面的法向量（叉乘）
N = cross(v1, v2);        % 平面法向量
% 计算平面的一般方程： N • (P - P0) = 0
% 即 N(1)*(x - x0) + N(2)*(y - y0) + N(3)*(z - z0) = 0
% 可以简化为：N • P - d = 0，其中 d = N • P0
d = dot(N, P1);
% 计算所有点到该平面的有向距离（点积）
dot_vals = V_pi * N';   % 每行是一个点与法向量的点积
keep_idx = dot_vals >= d;
V_pi_filtered = V_pi(keep_idx, :); % 删除平面"下方"的点

if max(abs(V_pi(:))) <= 1
    V_pi = V_pi*1000;
end

%% --- Build KD-tree for cortex surface ---
MdlPial = KDTreeSearcher(V_pi);

%% --- Compute depth = min distance to cortex ---
[~, dCortex] = knnsearch(MdlPial, P_mm);   % Euclidean distance (mm)

%% 直接计算最近点的欧氏距离
% dBrute = zeros(size(P_mm,1),1);
% for m=1:size(P_mm,1)
%     diffs = V_pi - P_mm(m,:);
%     dists = sqrt(sum(diffs.^2,2));
%     dBrute(m) = min(dists);
% end


%% --- Build results table ---
T = table(names, dCortex, ...
          'VariableNames', {'Contact','DepthFromCortex_mm'});

%% --- Save to CSV ---
writetable(T, out_csv);

fprintf('Done. CSV saved at:\n  %s\n', out_csv);
