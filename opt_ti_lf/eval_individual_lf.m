function [f, info] = eval_individual_lf(individual, fields_constant, elec_to_idx, ...
    geo_cache, currents, target_str, lambda, m2m_folder)
% 基于预计算电场的 TI 个体适应度评估（查表叠加，毫秒级）
%
% 输入:
%   individual      : 4 个电极名称的 cell array [e1, e2, e3, e4]
%   fields_constant : parallel.pool.Constant 封装的预计算电场 [N_elec, N_gm, 3]
%   elec_to_idx     : containers.Map 电极名→索引
%   geo_cache       : 预计算的 ROI 几何缓存
%   currents        : [I, -I] 电流值
%   target_str      : 靶区目标场强 (V/m)
%   lambda          : 惩罚系数
%
% 输出:
%   f           : 适应度值
%   info        : 详细信息结构体

    try
        fields = fields_constant.Value;

        % ========== 查表获取电场 ==========
        % 对每对电极: E_pair = E_pre(e_a) - E_pre(e_b)
        % 参考电极的贡献在减法中抵消
        i1 = get_idx(individual{1}, elec_to_idx, fields);
        i2 = get_idx(individual{2}, elec_to_idx, fields);
        i3 = get_idx(individual{3}, elec_to_idx, fields);
        i4 = get_idx(individual{4}, elec_to_idx, fields);

        E1 = squeeze(fields(i1, :, :)) - squeeze(fields(i2, :, :));
        E2 = squeeze(fields(i3, :, :)) - squeeze(fields(i4, :, :));

        % ========== 计算 TI 包络 ==========
        TI = get_maxTI(E1, E2);

        % ========== 加权统计 ==========
        gm_vols = geo_cache.gm_volumes;
        roi_mask = geo_cache.roi_mask;
        non_roi_mask = geo_cache.non_roi_mask;

        roi_avg = sum(TI(roi_mask) .* gm_vols(roi_mask)) / geo_cache.roi_volume;
        rest_avg = sum(TI(non_roi_mask) .* gm_vols(non_roi_mask)) / geo_cache.non_roi_volume;

        % ========== 峰值 ==========
        [peak_val, peak_idx] = max(TI);
        peak_center = geo_cache.gm_centers(peak_idx, :);
        peak_mni = subject2mni_coords(peak_center, m2m_folder);

        % ========== 适应度 ==========
        if isnan(roi_avg) || isnan(rest_avg) || rest_avg < 1e-12
            f = -1e6;
            info = struct('roi_avg', NaN, 'rest_avg', NaN, ...
                'focus_ratio', NaN, 'mod_depth', NaN, ...
                'focus_vol_total', NaN, 'peak_mni', NaN(1,3));
            peak_mni = NaN(1,3);
        else
            F = roi_avg / rest_avg;
            penalty = lambda * max(0, target_str - roi_avg)^2;
            f = F - penalty;

            % 聚焦体积
            fwhm = peak_val / 2;
            above_fwhm = TI >= fwhm;
            focus_vol_total = sum(gm_vols(above_fwhm));
            roi_above = above_fwhm & roi_mask;
            focus_vol_roi = sum(gm_vols(roi_above));
            if focus_vol_total > 0
                focus_ratio = focus_vol_roi / focus_vol_total;
            else
                focus_ratio = NaN;
            end

            % 调制深度
            roi_TI = TI(roi_mask);
            mod_depth = (max(roi_TI) - min(roi_TI)) / roi_avg;

            info = struct();
            info.roi_avg         = roi_avg;
            info.rest_avg        = rest_avg;
            info.focus_ratio     = focus_ratio * 100;
            info.mod_depth       = mod_depth;
            info.focus_vol_total = focus_vol_total;
            info.peak_mni        = peak_mni;
        end

    catch ME
        warning('评估个体失败 [%s]: %s', strjoin(individual, ','), ME.message);
        f = -1e6;
        info = struct('roi_avg', NaN, 'rest_avg', NaN, ...
            'focus_ratio', NaN, 'mod_depth', NaN, ...
            'focus_vol_total', NaN, 'peak_mni', NaN(1,3));
    end
end




function idx = get_idx(elec_name, elec_to_idx, fields)
% 获取电极在预计算数组中的索引
    if ~isKey(elec_to_idx, elec_name)
        error('电极 %s 不在预计算数据中', elec_name);
    end
    idx = elec_to_idx(elec_name);
end
