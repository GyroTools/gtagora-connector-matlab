classdef (Abstract, HandleCompatible) DownloadDatasetMixin   
    methods(Abstract)
        datasets = get_datasets(self);        
    end

    methods
        function downloaded_files = download(self, path)
            datasets = self.get_datasets();
            downloaded_files = {};
            for i = 1:length(datasets)
                downloaded_files = [downloaded_files, datasets(i).download(path)];
            end
        end    

        function downloaded_files = download_optimized(self, path, stream, compression, keep_zip_files)                                   
            narginchk(2,5);
            if nargin < 3
                stream = false;
            end
            if nargin < 4
                compression = false;
            end
            if nargin < 5
                keep_zip_files = false;
            end
            MAX_FILESIZE_TO_ZIP_MB = 20;
            MAX_ZIP_SIZE_MB = 20;

            info = self.download_info();
            datafiles_to_zip = [];
            zip_size = 0;
            downloaded_files = {};
            if ~isempty(info)
                for i = 1:length(info)
                    if info(i).size / 1024 / 1024 > MAX_FILESIZE_TO_ZIP_MB
                        % download directly
                        df = info(i).to_datafile();                        
                        final_path = fullfile(path, info(i).rel_path);
                        downloaded_files = [downloaded_files, df.download(final_path)];                       
                    else
                        % download in zip                           
                        datafiles_to_zip(end+1) = info(i).id;
                        zip_size = zip_size + info(i).size;
                        if zip_size / 1024 / 1024 > MAX_ZIP_SIZE_MB
                            downloaded_files = [downloaded_files, self.download_zip(datafiles_to_zip, path, stream, compression, keep_zip_files)];                             
                            datafiles_to_zip = [];
                            zip_size = 0;
                        end
                    end
                end
                downloaded_files = [downloaded_files, self.download_zip(datafiles_to_zip, path, stream, compression, keep_zip_files)];    
            end
        end   

        function info = download_info(self)
            import agora_connector.models.DownloadInfo           
            body = self.get_base_body();
            info = DownloadInfo(self.http_client);
            data = self.http_client.post(info.BASE_URL, body, 60);
            
            info = info.fill_from_data_array(data);               
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
        function filename = download_zip(self, datafile_ids, path, stream, compression, keep_zip_files)
            import agora_connector.models.DownloadFile 
            if ~isempty(datafile_ids)
                % download zip
                url = DownloadFile.project_url(self.project); 
                body = self.get_base_body();
                body.stream = stream;
                body.compression = compression;
                body.filter.datafile_ids = datafile_ids;
                data = self.http_client.post(url, body, 60);
                download_file = DownloadFile(self.http_client);
                download_file.fill_from_data(data);
                while(~download_file.ready)
                    pause(0.5);
                    download_file.get(download_file.id, download_file.http_client);                                
                end                
                filename = [tempname, '.zip'];                
                url = [DownloadFile.BASE_URL, num2str(download_file.id), '/download/'];
                download_file.http_client.download(url, filename);
                if exist(filename, 'file')
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

