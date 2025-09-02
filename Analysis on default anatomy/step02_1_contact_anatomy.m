%% ====== EDIT THESE PATHS ======
% Brainstorm folder (where brainstorm.m lives)
bst_dir      = 'D:\MATLAB_FOLDER\brainstorm3';  % <--- EDIT

% Your projected channel file (in default anatomy/MNI), e.g. merged file
channel_file = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\data\Group_channels\@intra\channel.mat';  % <--- EDIT

% Folder containing the default subject atlases
atlas_dir    = 'D:\SLEEP_PROJECT\MR_CT\Recons_Imaging\scalp_iEEG\anat\@default_subject';  % <--- EDIT

% Which atlases to use
atlas_files = { ...
    fullfile(atlas_dir,'subjectimage_neuromorphometrics_volatlas.mat'), ...
    fullfile(atlas_dir,'subjectimage_hammers_volatlas.mat'), ...
    fullfile(atlas_dir,'subjectimage_aal3_volatlas.mat') };

out_dir = 'D:\SLEEP_PROJECT\MR_CT\Analysis_Code';
% Search radius (mm) around the voxel if the exact voxel is unlabeled (=0)
search_radius_mm = 2;

%% ====== Set up Brainstorm path (no GUI needed) ======
if exist('brainstorm','file') ~= 2
    addpath(bst_dir);           % makes "brainstorm" available
end
if ~brainstorm('status')
    brainstorm nogui;                       % this adds toolbox/anatomy and others
end

assert(exist('cs_convert','file')==2, ...
  'cs_convert not found; check bst_dir or add toolbox manually.');

%% ====== Load channel file ======
S = load(channel_file);
if ~isfield(S,'Channel'); error('channel_file has no variable "Channel".'); end
Channel = S.Channel;

% Extract contact names and SCS coordinates (mm)
names = strings(numel(Channel),1);
xyzmm = nan(numel(Channel),3);
for k = 1:numel(Channel)
    names(k) = string(Channel(k).Name);
    if ~isempty(Channel(k).Loc)
        xyzmm(k,:) = (Channel(k).Loc(:,1)).';  % in SCS meters
        % xyzmm(k,:) = (1000 .* Channel(k).Loc(:,1)).';  % meters -> mm
    end
end

%% ====== Helpers ======
% Map atlas label name to LOBE bucket
function lobe = map_to_lobe(lbl)
    s = lower(string(lbl));
    lobe = "Unknown";

    if contains(s,["cerebell"])
        lobe = "Cerebellum"; return
    end
    if contains(s,["brainstem","midbrain","pons","medulla"])
        lobe = "Brainstem"; return
    end
    if contains(s,["insula","insular"])
        lobe = "Insula"; return
    end
    if contains(s,["hippocamp","amygdal","parahipp","cingulat","fornix","entorhinal","uncus","limbic"])
        lobe = "Limbic"; return
    end
    if contains(s,["thalam","caudate","putamen","pallid","accumb","ventral dienceph","claustrum","substantia nigra","subthalam","globus"])
        lobe = "Deep"; return
    end

    % Frontal area names
    if contains(s,["frontal","precentral","orbitofrontal","rectus","olfactory","supplementary motor","sma","pars opercularis","pars triangularis","pars orbitalis"])
        lobe = "Frontal"; return
    end
    % Temporal area names
    if contains(s,["temporal","heschl","fusiform","temporal pole","planum temporale","planum polare"])
        lobe = "Temporal"; return
    end
    % Parietal area names
    if contains(s,["parietal","postcentral","supramarginal","angular","precuneus"])
        lobe = "Parietal"; return
    end
    % Occipital area names
    if contains(s,["occipital","calcarine","lingual","cuneus"])
        lobe = "Occipital"; return
    end

    % AAL-style compact names (e.g., Frontal_Sup, Temporal_Mid, etc.)
    if contains(s,["frontal_"]),   lobe = "Frontal";   return; end
    if contains(s,["temporal_"]),  lobe = "Temporal";  return; end
    if contains(s,["parietal_"]),  lobe = "Parietal";  return; end
    if contains(s,["occipital_"]), lobe = "Occipital"; return; end
end

% Find atlas label and lobe at a coordinate (mm), with small neighborhood search
function [lbl, lobe] = label_from_volatlas(Mri, pt_m, r_mm)
    lbl = ""; lobe = "Unknown";
    if any(isnan(pt_m)), return; end

    % Convert SCS(mm) -> voxel indices
    vox = cs_convert(Mri, 'scs', 'voxel', pt_m);
    vox = round(vox);
    sz  = size(Mri.Cube);

    % Helper to read cube safely
    function val = getval(ii,jj,kk)
        if ii>=1 && ii<=sz(1) && jj>=1 && jj<=sz(2) && kk>=1 && kk<=sz(3)
            val = double(Mri.Cube(ii,jj,kk));
        else
            val = 0;
        end
    end

    val = getval(vox(1),vox(2),vox(3));

    % If empty (0), search a small sphere around the voxel
    if val==0 && r_mm>0
        rvox = max(1, round(r_mm ./ double(Mri.Voxsize(:)')));
        [dx,dy,dz] = ndgrid(-rvox(1):rvox(1), -rvox(2):rvox(2), -rvox(3):rvox(3));
        d2 = (dx.*double(Mri.Voxsize(1))).^2 + ...
             (dy.*double(Mri.Voxsize(2))).^2 + ...
             (dz.*double(Mri.Voxsize(3))).^2;
        mask = d2 <= (r_mm^2 + eps);
        cand = [vox(1)+dx(mask), vox(2)+dy(mask), vox(3)+dz(mask)];
        for ii = 1:size(cand,1)
            val = getval(cand(ii,1), cand(ii,2), cand(ii,3));
            if val ~= 0, break; end
        end
    end

    if val~=0 && isfield(Mri,'Labels') && ~isempty(Mri.Labels)
        % In Brainstorm vol-atlases, Cube value indexes into Labels rows
        try
            index = find([Mri.Labels{:,1}] == val);
            name = string(Mri.Labels{index,2});
            lbl  = name;
            lobe = map_to_lobe(name);
        catch
            % Fallback if "Labels" is structured differently
            lbl  = "LabelID_"+string(val);
            lobe = map_to_lobe(lbl);
        end
    end
end

%% ====== Label with each atlas and assemble table ======
n = numel(names);
atlas_names = strings(numel(atlas_files),1);
region      = strings(n, numel(atlas_files));
lobe        = strings(n, numel(atlas_files));

% Load atlases
Mris = cell(numel(atlas_files),1);
for a = 1:numel(atlas_files)
    Mris{a} = load(atlas_files{a});
    atlas_names(a) = string(erase(extractAfter(atlas_files{a},"subjectimage_"),"_volatlas.mat"));
end

% For each contact, query each atlas
for k = 1:n
    for a = 1:numel(Mris)
        [region(k,a), lobe(k,a)] = label_from_volatlas(Mris{a}, xyzmm(k,:), search_radius_mm);
    end
end

% Majority-vote / priority final lobe (Neuromorphometrics > Hammers > AAL3)
final_lobe = strings(n,1);
for k = 1:n
    % vote among non-Unknown
    vals = lobe(k, lobe(k,:)~="");
    vals = vals(vals~="Unknown");
    if ~isempty(vals)
        % priority order
        pr = ["neuromorphometrics","hammers","aal3"];
        chosen = "";
        for p = pr
            idx = find(contains(lower(atlas_names), p), 1);
            if ~isempty(idx) && lobe(k,idx)~="" && lobe(k,idx)~="Unknown"
                chosen = lobe(k,idx); break
            end
        end
        if chosen=="", chosen = mode(vals); end
        final_lobe(k) = chosen;
    else
        final_lobe(k) = "Unknown";
    end
end

% Build output table
T = table(names, xyzmm(:,1), xyzmm(:,2), xyzmm(:,3), final_lobe, ...
    'VariableNames', {'Contact','Xmm','Ymm','Zmm','Lobe_Final'});

% Add per-atlas region & lobe columns
for a = 1:numel(atlas_names)
    T.("Region_"+atlas_names(a)) = region(:,a);
    T.("Lobe_"+atlas_names(a))   = lobe(:,a);
end

% Save CSV next to the channel file
[~, out_base, ~] = fileparts(channel_file);
csv_path = fullfile(out_dir, out_base + "_lobes.csv");
writetable(T, csv_path);

fprintf('Done. Lobe table saved:\n  %s\n', csv_path);
