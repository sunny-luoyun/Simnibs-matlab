function [f, info] = eval_individual(individual, m2m_folder, output_root, mni_target, ...
    roi_radius, currents, shape, dimensions, thickness, target_str, lambda)
% 适应度函数：ROI_avg / Rest_avg + 强度惩罚
%
% 参考文献:
%   [1] Lee et al., Sci Rep 10, 13653 (2020)
%       Peak Ratio = E_target / E_cortex, constraint E_target > 0.2 V/m
%   [2] Stoupis & Samaras, bioRxiv 2022.02.10.477970 (2022)
%       Fitness = ROI_avg / Rest_avg via genetic algorithm

    % 生成唯一临时目录（基于时间和随机数，避免并行冲突）
    temp_dir = fullfile(output_root, sprintf('temp_%s_%d', ...
                      datestr(now,'yyyymmdd_HHMMSS'), randi(1e7)));
    mkdir(temp_dir);

    try
        electrode_centres = {individual(1:2), individual(3:4)};
        TIS(m2m_folder, temp_dir, currents, electrode_centres, shape, dimensions, thickness);
        res = look_efield(temp_dir, m2m_folder, mni_target, roi_radius);

        roi_avg = res.roi.avg;
        rest_avg = max(res.non_roi.avg, 1e-12);
        focus_ratio = res.modulation.focus_ratio;
        focus_vol_total = res.modulation.focus_volume_total_mm3;

        if isnan(roi_avg) || isnan(rest_avg)
            f = -1e6;
        info = struct('roi_avg', NaN, 'rest_avg', NaN, 'focus_ratio', NaN, 'mod_depth', NaN, ...
              'focus_vol_total', NaN, 'peak_mni', NaN(1,3));
        else
            % [1] Lee et al. 2020: Peak Ratio + intensity constraint
            % [2] Stoupis & Samaras 2022: ROI_avg / Rest_avg
            F = roi_avg / rest_avg;
            penalty = lambda * max(0, target_str - roi_avg)^2;
            f = F - penalty;

            info.roi_avg         = roi_avg;
            info.rest_avg        = rest_avg;
            info.focus_ratio     = focus_ratio;
            info.mod_depth       = res.modulation.depth;
            info.focus_vol_total = focus_vol_total;
            info.peak_mni        = res.peak.mni_coord;
        end
    catch ME
        warning('评估个体失败: %s', strjoin(individual, ','));
        disp(ME.message);
        f = -1e6;
        info = struct('roi_avg', NaN, 'focus_ratio', NaN, 'mod_depth', NaN, ...
              'focus_vol_total', NaN, 'peak_mni', NaN(1,3));
    end;

    % 清理临时文件夹
    try
        rmdir(temp_dir, 's');
    catch
        warning('无法删除临时文件夹: %s', temp_dir);
    end
end