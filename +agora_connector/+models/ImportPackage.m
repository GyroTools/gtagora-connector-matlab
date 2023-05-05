classdef ImportPackage < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        last_progress = [];
        zip_upload = false;
    end

    properties (Constant)
        BASE_URL = '/api/v1/import/';
    end

    methods
        function self = ImportPackage(http_client)
            if nargin == 0
                http_client = [];
            end
            self = self@agora_connector.models.BaseModel(http_client);
        end

        function self = create(self)
            url = self.BASE_URL;
            data = self.http_client.post(url, [], 60);
            if isfield(data, 'id')
                self = self.fill_from_data(data);
                return;
            end
            error('cannot create an Import object');
        end

        function data = upload(self, path, target_folder_id, json_import_file, wait, timeout)
            import agora_connector.models.ZipUploadFiles

            data = [];
            if nargin < 2
                target_folder_id = [];
            end
            if nargin < 4
                json_import_file = [];
            end
            if nargin < 5
                wait = true;
            end
            if nargin < 6
                timeout = 1800;
            end           

            if ~ischar(path)
                error('path must be a string');
            end

            [input_files, target_files] = self.prepare_path_to_upload(path);

            base_url = ['/api/v1/import/', num2str(self.id), '/'];
            url = [base_url, 'upload/'];

            if self.check_zip_option(input_files)
                temp_dir = tempname;
                status = mkdir(temp_dir);
                if ~status
                    error('cannot create a temporary directory');
                end
                zip_uploader = ZipUploadFiles(input_files, target_files);
                [input_files, target_files] = zip_uploader.create_zip(temp_dir);
                self.http_client.upload(url, input_files, target_files);
                try
                    rmdir(temp_dir, 's');
                catch
                end
            else
                self.zip_upload = false;
                self.http_client.upload(url, input_files, target_files);
            end

            self.complete(json_import_file, target_folder_id)
            if wait
                start_time = datetime;
                while seconds(datetime - start_time) < timeout
                    data = self.progress();
                    if isempty(data)
                        error('cannot get the progress');
                    end
                    if data.state == 5 || data.state == -1
                        return
                    end
                    pause(5);
                end
            end
        end

        function complete(self, json_import_file, target_folder_id)
            if nargin < 2
                json_import_file = [];
            end
            if nargin < 3
                target_folder_id = [];
            end
            url = [self.BASE_URL, num2str(self.id), '/complete/'];
            post_data = struct;
            if ~isempty(json_import_file)
                post_data.import_file = json_import_file;
            end
            if ~isempty(target_folder_id)
                post_data.folder = target_folder_id;
            end
            response = self.http_client.post(url, post_data, 120);            
        end

        function data = progress(self)            
            url = [self.BASE_URL, num2str(self.id), '/progress/'];
            data = self.http_client.get(url);
            if isfield(data, 'state')
                self.last_progress = data;                
            end
        end
    end

    methods (Hidden, Static)
        function [input_files, target_files] = prepare_path_to_upload(path)
            input_files = {};
            target_files = {};
            
            if isfolder(path)
                root = path;
                filelist = dir(fullfile(path, '**\*.*'));
                for j = 1:length(filelist)
                    if ~filelist(j).isdir
                        absolute_file_path = fullfile(filelist(j).folder, filelist(j).name);
                        input_files{end+1} = absolute_file_path;
                        target = strrep(absolute_file_path, root, '');
                        target = strrep(target, '\', '/');
                        if length(target) > 1 && target(1) == '/'
                            target = target(2:end);
                        end
                        target_files{end+1} = target;                       
                    end
                end
            elseif isfile(path)
                input_files{end+1} = path;
                [~, filename, ext] = fileparts(path);
                target_files{end+1} = [filename, ext];
            end            
        end

        function val = check_zip_option(input_files)
            val = length(input_files) > 5;
        end
    end
end

