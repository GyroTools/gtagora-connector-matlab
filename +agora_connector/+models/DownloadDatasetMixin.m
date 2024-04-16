classdef (Abstract, HandleCompatible) DownloadDatasetMixin    
    methods       
        function downloaded_files = download(self, path, varargin)
            p = inputParser;
            booleanValidator = @(x) islogical(x) || (isnumeric(x) && isscalar(x) && (x == 0 || x == 1));
            addOptional(p,'stream', true, booleanValidator);
            addOptional(p,'compression', false, booleanValidator);
            addOptional(p,'keep_zip_files', false, booleanValidator);
            addOptional(p,'progress', false, booleanValidator);
            addOptional(p,'max_size_to_zip', 20, @isnumeric);
            addOptional(p,'subfolder',true, booleanValidator);
            parse(p, varargin{:});
            options = p.Results;
           
            if nargin < 2
                error('please specify a download directory as argument')
            end
            narginchk(2,10);            
            if options.progress
                disp('analysing download...');
            end
            info = self.download_info();
            downloaded_files = {};
            if ~isempty(info)                
                exist_mask = arrayfun(@(i) agora_connector.models.Datafile.files_exists( fullfile(fullfile(path, i.rel_path), i.filename), i.size, i.sha1), info);
                info = info(~exist_mask);
                if isempty(info) && options.progress
                    disp('all files already exist');
                    return;
                end
                direct_download_mask = arrayfun(@(i) i.size / 1024 / 1024 > options.max_size_to_zip, info, 'UniformOutput', true);
                direct = info(direct_download_mask);                
                exist_mask = arrayfun(@(i) agora_connector.models.Datafile.files_exists( fullfile(fullfile(path, i.rel_path), i.filename), i.size, i.sha1), direct);
                direct = direct(~exist_mask);
                for i = 1:length(direct)
                    % download directly
                    df = direct(i).to_datafile();
                    if options.subfolder
                        final_path = fullfile(path, direct(i).rel_path);
                    else
                        final_path = fullfile(path);
                    end
                    if options.progress
                        disp(['downloading ', fullfile(final_path, df.original_filename), '...']);
                    end
                    downloaded_files = [downloaded_files, df.download(final_path)];
                end
                zipped = info(~direct_download_mask);                               
                if ~isempty(zipped)
                    datafiles_to_zip = arrayfun(@(i) i.id, zipped, 'UniformOutput', true);
                    % TODO maybe limit the size of the zip file or the amount
                    % of files in the zip file (not sure if it is necessary)
    
                    downloaded_files = [downloaded_files, self.download_zip(datafiles_to_zip, path, options.stream, options.compression, options.keep_zip_files, options.progress)];
                end
            else
                if options.progress
                    disp('nothing to download!');
                end
            end
        end

        function info = download_info(self)
            import agora_connector.models.DownloadInfo
            body = self.get_base_body();
            info = DownloadInfo(self.http_client);
            data = self.http_client.post(info.BASE_URL, body, 60);

            info = info.fill_from_data_array(data);
        end

        function downloaded_files = download_legacy(self, path)
            datasets = self.get_datasets();
            downloaded_files = {};
            for i = 1:length(datasets)
                downloaded_files = [downloaded_files, datasets(i).download(path)];
            end
        end       
    end

    methods (Hidden, Access=protected)
        function body = get_base_body(self)
            body = struct();
            if isa(self, 'agora_connector.models.Exam')
                body.exam_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Folder')
                body.folder_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Series')
                body.series_ids = {self.id};
            elseif isa(self, 'agora_connector.models.Dataset')
                body.dataset_ids = {self.id};
            end
        end
        function filename = download_zip(self, datafile_ids, path, stream, compression, keep_zip_files, progress)
            import agora_connector.models.DownloadFile
            if ~isempty(datafile_ids)
                % download zip
                url = DownloadFile.project_url(self.project);
                body = self.get_base_body();
                body.stream = stream;
                body.compression = compression;
                body.filter.datafile_ids = datafile_ids;
                if progress
                    disp('requesting zip file...');
                end
                data = self.http_client.post(url, body, 60);
                download_file = DownloadFile(self.http_client);
                download_file.fill_from_data(data);
                while(~download_file.ready)
                    pause(0.5);
                    download_file.get(download_file.id, download_file.http_client);
                end
                filename = [tempname, '.zip'];
                url = [DownloadFile.BASE_URL, num2str(download_file.id), '/download/'];
                if progress
                    disp(['downloading ', filename, '...']);
                end
                download_file.http_client.download(url, filename);
                if exist(filename, 'file')
                    if progress
                        disp('unzipping...');
                    end
                    unzip(filename,path);
                end
                if ~keep_zip_files
                    try
                        delete(filename);
                    catch
                    end
                end
            end
        end
    end
end

