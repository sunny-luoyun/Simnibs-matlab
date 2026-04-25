function run_charm_segmentation(t1Path, outputPath, subjectID, t2Path)
% run_charm_segmentation 执行 CHARM 结构像分割流程
%   t1Path      - T1 输入路径（.nii/.nii.gz 文件或 DICOM 文件夹）
%   outputPath  - 结果输出目录
%   subjectID   - 被试编号（如 'Sub001'）
%   t2Path      - （可选）T2 路径，若提供则用于双通道分割

    % 1. 转换 T1 到 NIfTI
    niftiT1Path = convert_dicom_to_nifti(t1Path, outputPath, subjectID, 'T1');
    fprintf('T1 NIfTI 文件：%s\n', niftiT1Path);

    % 2. 转换 T2 到 NIfTI（如果提供了 T2 路径）
    if nargin >= 4 && ~isempty(t2Path)
        niftiT2Path = convert_dicom_to_nifti(t2Path, outputPath, subjectID, 'T2');
        fprintf('T2 NIfTI 文件：%s\n', niftiT2Path);
    else
        niftiT2Path = [];
    end

    % 3. 执行 CHARM 命令（使用 system + '-echo' 实现实时输出）
    if isempty(niftiT2Path)
        cmd = sprintf('charm %s "%s" --forcerun', subjectID, niftiT1Path);
    else
        cmd = sprintf('charm %s "%s" "%s" --forcerun', subjectID, niftiT1Path, niftiT2Path);
    end

    fprintf('CHARM 正在运行，实时输出如下：\n');
    tic;  % 开始计时
    [status, cmdout] = system(cmd, '-echo');
    elapsed = toc;  % 结束计时
    if status ~= 0
        error('CHARM 命令执行失败，退出码：%d\n%s', status, cmdout);
    end
    fprintf('\nCHARM 执行完成，总耗时：%.2f 秒。\n', elapsed);

    % 4. 移动生成的 m2m 文件夹到输出目录
    m2mFolder = fullfile(pwd, sprintf('m2m_%s', subjectID));
    if exist(m2mFolder, 'dir')
        targetM2M = fullfile(outputPath, sprintf('m2m_%s', subjectID));
        if exist(targetM2M, 'dir')
            rmdir(targetM2M, 's');
        end
        movefile(m2mFolder, targetM2M);
        fprintf('已将 m2m 文件夹移动到：%s\n', targetM2M);
    else
        warning('未找到 m2m 文件夹 %s，可能 CHARM 未正常生成。', m2mFolder);
    end
end

function niftiPath = convert_dicom_to_nifti(inputPath, outputPath, subjectID, modality)
% 将 DICOM 文件夹或已有 NIfTI 文件转换为统一的 NIfTI 路径
%   inputPath  - DICOM 文件夹或 NIfTI 文件路径
%   outputPath - 输出目录（仅当 inputPath 是 DICOM 文件夹时使用）
%   subjectID  - 被试编号
%   modality   - 模态名称，如 'T1'、'T2'（默认为 'T1'）
    if nargin < 4
        modality = 'T1';
    end

    if ~exist(inputPath, 'file') && ~exist(inputPath, 'dir')
        error('输入路径不存在：%s', inputPath);
    end

    % 若输入是文件，检查是否为 NIfTI
    if exist(inputPath, 'file') == 2
        [~, ~, ext] = fileparts(inputPath);
        if strcmpi(ext, '.gz')
            % .nii.gz 情况：需要再判断基础扩展名
            [~, name, ~] = fileparts(inputPath);
            [~, ~, ext2] = fileparts(name);
            if strcmpi(ext2, '.nii')
                niftiPath = inputPath;
                return;
            end
        elseif strcmpi(ext, '.nii')
            niftiPath = inputPath;
            return;
        else
            error('输入文件不是 NIfTI 格式：%s', inputPath);
        end
    end

    % 若是文件夹，则用 dcm2niix 转换
    if exist(inputPath, 'dir') == 7
        baseName = sprintf('%s%s', subjectID, modality);
        cmd = sprintf('dcm2niix -o "%s" -f "%s" -z y -s y "%s"', ...
                      outputPath, baseName, inputPath);
        fprintf('执行 dcm2niix：%s\n', cmd);
        [status, cmdout] = system(cmd);
        if status ~= 0
            error('dcm2niix 执行失败：\n%s', cmdout);
        end

        % 查找生成的 NIfTI 文件（可能因转换细节略有差异）
        pattern = fullfile(outputPath, [baseName '*.nii.gz']);
        files = dir(pattern);
        if isempty(files)
            % 尝试无压缩的 .nii
            pattern = fullfile(outputPath, [baseName '*.nii']);
            files = dir(pattern);
        end
        if isempty(files)
            error('dcm2niix 转换后未找到预期的 NIfTI 文件（模式：%s）。', pattern);
        end
        niftiPath = fullfile(outputPath, files(1).name);
        return;
    end

    error('输入路径类型未知：%s', inputPath);
end