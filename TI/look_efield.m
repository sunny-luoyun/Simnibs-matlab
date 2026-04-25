function result = look_efield(TI_folder, m2m_folder, MNI_coords, radius)
% 计算 ROI 内/外及全脑灰质 TI 包络振幅的详细统计信息
% 输入：
%   TI_folder   : 包含 TI 包络网格文件的文件夹
%   m2m_folder  : m2m 文件夹路径
%   MNI_coords  : MNI 坐标 [x y z]
%   radius      : ROI 半径 (mm)
% 输出：
%   result - 结构体，包含：
%       .roi      : ROI 内统计量 (avg, std, median, min, max, values, volume, num_elements)
%       .non_roi  : 灰质中 ROI 外的统计量
%       .whole_gm : 全脑灰质的统计量
%       .info     : 计算参数与基本信息
%       .gm_field : 整个灰质的场值向量 (可用于进一步绘图)
%       .gm_centers : 灰质单元中心坐标 (subject 空间)

    % ----- 获取被试名 -----
    [~, folder_name] = fileparts(m2m_folder);
    if startsWith(folder_name, 'm2m_')
        subject = folder_name(5:end);
    else
        subject = folder_name;
    end

    % ----- 加载网格 -----
    mesh_file = fullfile(TI_folder, sprintf('%s_TIenvelope_only.msh', subject));
    if ~exist(mesh_file, 'file')
        error('找不到文件: %s', mesh_file);
    end
    head_mesh = mesh_load_gmsh4(mesh_file);
    gray_matter = mesh_extract_regions(head_mesh, 'region_idx', 2);
    if isempty(gray_matter) || isempty(gray_matter.element_data)
        error('灰质区域未找到或网格数据缺失');
    end

    % ----- 坐标转换 -----
    subject_coords = mni2subject_coords(MNI_coords, m2m_folder);

    % ----- 灰质单元中心与体积 -----
    elm_centers = mesh_get_tetrahedron_centers(gray_matter);
    elm_vols    = mesh_get_tetrahedron_sizes(gray_matter);

    % ----- 加载场数据 -----
    field_name = 'maxTIamplitude';
    field_idx = get_field_idx(gray_matter, field_name, 'elements');
    if isempty(field_idx)
        error('网格中未找到字段: %s', field_name);
    end
    field = gray_matter.element_data{field_idx}.tetdata;

    % ----- 定义 ROI 掩膜 -----
    distances = sqrt(sum((elm_centers - subject_coords).^2, 2));
    roi_mask  = distances < radius;
    non_roi_mask = ~roi_mask;

    % ----- 基本统计函数 -----
    weighted_avg = @(v, mask) sum(v(mask) .* elm_vols(mask)) / sum(elm_vols(mask));
    weighted_std = @(v, mask) sqrt( sum(elm_vols(mask) .* (v(mask) - weighted_avg(v,mask)).^2 ) / sum(elm_vols(mask)) );
    % 注：中位数、最小、最大直接基于单元（不做体积加权），若需体积加权分位数可自行修改
    median_val = @(v, mask) median(v(mask));
    min_val    = @(v, mask) min(v(mask));
    max_val    = @(v, mask) max(v(mask));

    % ----- 计算统计量 -----
    if any(roi_mask)
        result.roi.avg    = weighted_avg(field, roi_mask);
        result.roi.std    = weighted_std(field, roi_mask);
        result.roi.median = median_val(field, roi_mask);
        result.roi.min    = min_val(field, roi_mask);
        result.roi.max    = max_val(field, roi_mask);
        result.roi.values = field(roi_mask);             % ROI 内所有单元场值
        result.roi.volume = sum(elm_vols(roi_mask));     % mm³
        result.roi.num_elements = sum(roi_mask);
    else
        warning('ROI 内没有元素，请检查半径或坐标');
        result.roi = struct('avg',NaN, 'std',NaN, 'median',NaN, 'min',NaN, 'max',NaN,...
                            'values',[], 'volume',0, 'num_elements',0);
    end

    % ROI 外（灰质其余部分）
    if any(non_roi_mask)
        result.non_roi.avg    = weighted_avg(field, non_roi_mask);
        result.non_roi.std    = weighted_std(field, non_roi_mask);
        result.non_roi.median = median_val(field, non_roi_mask);
        result.non_roi.min    = min_val(field, non_roi_mask);
        result.non_roi.max    = max_val(field, non_roi_mask);
        result.non_roi.values = field(non_roi_mask);
        result.non_roi.volume = sum(elm_vols(non_roi_mask));
        result.non_roi.num_elements = sum(non_roi_mask);
    else
        result.non_roi = struct('avg',NaN, 'std',NaN, 'median',NaN, 'min',NaN, 'max',NaN,...
                                'values',[], 'volume',0, 'num_elements',0);
    end

    % 全脑灰质
    whole_mask = true(size(field));
    result.whole_gm.avg    = weighted_avg(field, whole_mask);
    result.whole_gm.std    = weighted_std(field, whole_mask);
    result.whole_gm.median = median_val(field, whole_mask);
    result.whole_gm.min    = min_val(field, whole_mask);
    result.whole_gm.max    = max_val(field, whole_mask);
    result.whole_gm.volume = sum(elm_vols);

    % ----- 附加信息 -----
    result.info = struct();
    result.info.subject        = subject;
    result.info.MNI_coords     = MNI_coords;
    result.info.radius_mm      = radius;
    result.info.field_name     = field_name;
    result.info.subject_coords = subject_coords;

    % ----- 便于绘图的完整数据 -----
    result.gm_field   = field;        % 所有灰质单元的 TI 场值
    result.gm_centers = elm_centers;  % 对应的单元中心坐标 (subject 空间)
    result.gm_volumes = elm_vols;     % 单元体积

    % ========== 新增：全脑灰质峰值电场坐标定位 ==========
    [peak_value, peak_idx] = max(field);                     % 最大场值及其索引
    peak_subj_coord = elm_centers(peak_idx, :);              % subject空间坐标
    % 转换为 MNI 坐标 (需要 SimNIBS 函数)
    peak_mni_coord = subject2mni_coords(peak_subj_coord, m2m_folder);

    result.peak = struct();
    result.peak.value       = peak_value;                   % 峰值电场 (V/m 或其他单位)
    result.peak.subject_coord = peak_subj_coord;            % [x y z] mm
    result.peak.mni_coord   = peak_mni_coord;               % [x y z] mm
    % =====================================================
    % ========== 新增：调制深度与半峰全宽(FWHM)聚焦体积 ==========
    % 1. 调制深度：定义为 (ROI内最大值 - ROI内最小值) / ROI内平均值
    %    反映靶区内包络振幅的相对起伏程度（无量纲）
    if ~isnan(result.roi.avg) && result.roi.avg > 0
        modulation_depth = (result.roi.max - result.roi.min) / result.roi.avg;
    else
        modulation_depth = NaN;
    end

    % 2. 半峰全宽(FWHM)阈值：使用全脑灰质峰值的一半
    half_max_threshold = result.peak.value / 2;

    % 3. 超过半峰全宽阈值的区域
    above_mask = field >= half_max_threshold;

    % 全脑灰质中超过阈值的总体积 (mm³)
    focus_volume_total = sum(elm_vols(above_mask));

    % 靶区内超过阈值的体积 (mm³)
    roi_above_mask = above_mask & roi_mask;
    focus_volume_roi = sum(elm_vols(roi_above_mask));

    % 4. 靶区占比（越接近1越好，表示超阈值能量全部集中在靶区）
    if focus_volume_total > 0
        focus_ratio = focus_volume_roi / focus_volume_total;
    else
        focus_ratio = NaN;
    end

    % 5. 综合指标：调制深度 / 聚焦体积 (mm⁻³)
    if focus_volume_total > 0
        mod_depth_over_focus_vol = modulation_depth / focus_volume_total;
    else
        mod_depth_over_focus_vol = NaN;
    end

    % 存入结构体
    result.modulation = struct();
    result.modulation.depth                      = modulation_depth;             % 调制深度（无量纲）
    result.modulation.fwhm_threshold             = half_max_threshold;           % 半峰全宽阈值
    result.modulation.focus_volume_total_mm3    = focus_volume_total;           % 超阈值总体积
    result.modulation.focus_volume_roi_mm3      = focus_volume_roi;             % 靶区内超阈值体积
    result.modulation.focus_ratio                = focus_ratio;                  % 靶区占比
    result.modulation.depth_over_focus_volume    = mod_depth_over_focus_vol;     % 你要求的比值
    % ================================================================

    result.roi_enhancement = result.roi.avg / result.whole_gm.avg;  % 如果需要增强比，可以额外加
end