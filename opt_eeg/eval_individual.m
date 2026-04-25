function [f, info] = eval_individual(individual, m2m_folder, output_root, mni_target, ...
    roi_radius, currents, shape, dimensions, thickness, w1, w2, w3, target_str, lambda)

    % 生成唯一临时目录（基于时间和随机数，避免并行冲突）
    temp_dir = fullfile(output_root, sprintf('temp_%s_%d', ...
                      datestr(now,'yyyymmdd_HHMMSS'), randi(1e7)));
    mkdir(temp_dir);

    try
        electrode_centres = {individual(1:2), individual(3:4)};
        TIS(m2m_folder, temp_dir, currents, electrode_centres, shape, dimensions, thickness);
        res = look_efield(temp_dir, m2m_folder, mni_target, roi_radius);

        roi_avg = res.roi.avg;
        whole_avg = max(res.whole_gm.avg, 1e-12);
        focus_ratio = res.modulation.focus_ratio;
        focus_vol_total = res.modulation.focus_volume_total_mm3;
        whole_vol = max(res.whole_gm.volume, 1e-12);

        if isnan(roi_avg) || isnan(focus_ratio)
            f = -1e6;
            info = struct('roi_avg', NaN, 'focus_ratio', NaN, 'mod_depth', NaN, ...
              'focus_vol_total', NaN, 'peak_mni', NaN(1,3));
        else
            F = w1 * (roi_avg / whole_avg) ...
              + w2 * (focus_ratio / 100) ...
              - w3 * (focus_vol_total / whole_vol);
            penalty = lambda * max(0, target_str - roi_avg)^2;
            f = F - penalty;

            info.roi_avg         = roi_avg;
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