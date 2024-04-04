classdef ImportPackage < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        last_progress = [];
        zip_upload = false;
        progress_string_length = [];
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

        function data = upload(self, path, target_folder_id, progress_file, json_import_file, wait, timeout)
            data = [];
            if nargin < 3
                target_folder_id = [];
            end
            if nargin < 4
                progress_file = [];
            end
            if nargin < 5
                json_import_file = [];
            end
            if nargin < 6
                wait = true;
            end
            if nargin < 7
                timeout = 1800;
            end 

            if ~isempty(progress_file) && ~exist(progress_file, 'file')
                folder = fileparts(progress_file);
                if ~isempty(folder) && ~exist(folder, 'dir')
                    error('the target folder for the progress file does not exist');
                end
            end

            state = self.create_state(path, target_folder_id, json_import_file, wait, timeout);
            state.save(progress_file);
            data = self.upload_from_state(state, progress_file);
        end

        function state = create_state(self, path, target_folder_id, json_import_file, wait, verbose, timeout)
            import agora_connector.models.UploadFile
            import agora_connector.models.UploadState
            import agora_connector.models.ZipUploadFiles

            if nargin < 3
                target_folder_id = [];
            end            
            if nargin < 4
                json_import_file = [];
            end
            if nargin < 5
                wait = true;
            end
            if nargin < 6
                verbose = true;
            end 
            if nargin < 7
                timeout = 1800;
            end 
            
            if ~ischar(path) && ~iscell(path)
                error('path must either be a string or a cell array of strings');
            end

            [input_files, target_files] = self.prepare_path_to_upload(path);             
            for i = 1:length(input_files)                
                uf = UploadFile();
                uf.id = i;
                uf.file = input_files{i};
                uf.target = target_files{i};

                s = dir(uf.file);         
                filesize = s.bytes;   
                uf.zip = length(input_files) > 5 && filesize < ZipUploadFiles.MAX_FILE_LIMIT;
                uf.size = filesize;                
                files(i) = uf;
            end
            state = UploadState();
            state.import_package = self.id;
            state.files = files;

            state.target_folder_id = target_folder_id;       
            state.json_import_file = json_import_file;
            state.wait = wait;
            state.timeout = timeout;   
            state.verbose = verbose;
        end

        function state = upload_from_state(self, state, progress_file)
            import agora_connector.models.ZipUploadFiles  

            function progress_callback(file)
                if ~isempty(state.files)
                    % Update state
                    index = find(strcmp({state.files.file}, file.file));
                    if ~isempty(index)
                        state.files(index) = file;
                    end
            
                    if ~isempty(progress_file)
                        state.save(progress_file);
                    end
            
                    if state.verbose
                        total_size = sum([state.files.size]);
                        ind_uploaded = find([state.files.uploaded] == 1);
                        size_uploaded = sum([state.files(ind_uploaded).size]);
                        if ~file.uploaded
                            size_uploaded = size_uploaded + file.size_uploaded;
                        elseif isempty(index)
                            % The file is a zip file and it is uploaded. However, the files in the state have not yet received
                            % the uploaded flag.
                            return;
                        end
            
                        files_uploaded = sum([state.files.uploaded]);
                        appendix = ['(' self.pretty_print_progress(size_uploaded, total_size) ', file ' num2str(files_uploaded) ' of ' num2str(numel(state.files)) ')'];
                        self.print_progress(size_uploaded/total_size, appendix);
                    end
                end
            end
            pc = @progress_callback;

            if ~ischar(path)
                error('path must be a string');
            end

            if state.verbose
                disp(['import package: ', num2str(self.id)]);
                disp("uploading...");
            end
            
            base_url = ['/api/v1/import/', num2str(self.id), '/'];
            url = [base_url, 'upload/'];
            zip_packages = self.create_zip_packages(state);

            if ~isempty(zip_packages)
                for i = 1:length(zip_packages)
                    package = zip_packages{i};
                    temp_dir = tempname;
                    status = mkdir(temp_dir);
                    if ~status
                        error('cannot create a temporary directory');
                    end
                    zip_filename=['upload_', char(java.util.UUID.randomUUID), '.agora_upload'];
                    zip_uploader = ZipUploadFiles(package);
                    files = zip_uploader.create_zip(temp_dir, true, zip_filename);
                    self.http_client.upload(url, files, self.http_client.TIMEOUT, pc);    
                    state = self.set_uploaded(state, package);
                    state.save(progress_file);
                    for i = 1:length(files)
                        try
                            delete(files(i).file);
                        catch end
                    end                   
                end
            end

            ind = find([state.files.zip] == 0 & [state.files.uploaded] == 0);
            files = state.files(ind);
            if ~isempty(files)
                self.http_client.upload(url, files, self.http_client.TIMEOUT, pc);
            end

            if state.verbose
                total_size = sum([state.files.size]);
                appendix = ['(' self.pretty_print_progress(total_size, total_size) ', file ' num2str(numel(state.files)) ' of ' num2str(numel(state.files)) ')'];
                self.print_progress(1, appendix)
                self.progress_string_length = [];
            end
            
            self.complete(state.json_import_file, state.target_folder_id)
            if state.wait
                if state.verbose    
                    fprintf('\n\n');
                    disp("importing data...")
                end
                start_time = datetime;
                while seconds(datetime - start_time) < state.timeout
                    data = self.progress();
                    if isempty(data)
                        error('cannot get the progress');
                    end
                    if data.state == 5 || data.state == 4
                        if state.verbose                              
                            count = data.tasks.count;
                            finished = data.tasks.finished;
                            progress = 0;
                            if count > 0
                                progress = finished / count;
                            end
                            self.print_progress(progress)
                        end
                        if data.state == 5 && data.progress == 100
                            if state.verbose
                                self.print_progress(1);
                                self.progress_string_length = [];
                            end
                            state = self.update_import_state(state);

                            state.save(progress_file);
                            if state.verbose
                                self.print_final_message(state);
                            end                            
                            return;
                        end                                              
                    elseif data.state == -1                        
                        error("Import failed!")                        
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

    methods(Hidden)
        function packages = create_zip_packages(self, state)
            j = 1;
            ind = find([state.files.zip] & ~[state.files.uploaded]);
            files_to_zip = state.files(ind);            
            compression_rate = 3;
            max_group_size = self.http_client.UPLOAD_CHUCK_SIZE * compression_rate;
            packages = self.group_files_by_size(files_to_zip, max_group_size);
        end
        function file_groups = group_files_by_size(self, files, max_group_size)
            file_groups = {};           
            j = 1;
            current_group_size = 0;
            
            grouped_by_root_path = {};   
            root_paths = {};
            for i = 1:numel(files)
                root_index = [];
                file = files(i);
                root = strrep(strrep(file.file, '\', '/'), file.target, '');
                for j = 1:length(root_paths)
                    if strcmp(root_paths{j}, root)
                        root_index = j;
                        break;
                    end
                end
                if isempty(root_index)
                    root_index = length(root_paths) + 1;
                    root_paths{root_index} = root;
                end
                if length(grouped_by_root_path) < root_index
                    grouped_by_root_path{root_index} = file;
                else
                    grouped_by_root_path{root_index}(end+1) = file;
                end                
            end
            
            for k = 1:length(grouped_by_root_path)
                files = grouped_by_root_path{k};
                clear current_group;
                j = 1;
                for i = 1:numel(files)
                    file = files(i);
                    file_path = file.file;
                    file_size = dir(file_path);
                    file_size = file_size.bytes;
            
                    if current_group_size + file_size > max_group_size
                        file_groups{end+1} = current_group;
                        clear current_group;
                        j = 1;
                        current_group_size = 0;
                    end
            
                    current_group(j) = file;
                    j = j+1;
                    current_group_size = current_group_size + file_size;
                end
            
                if ~isempty(current_group)
                    file_groups{end+1} = current_group;
                end
            end
        end

        function state = update_import_state(self, state)
            import agora_connector.utils.sha1
                        
            url = [self.BASE_URL num2str(self.id) '/result/'];
            
            try
                data = self.http_client.get(url);
            catch
                warning('could not verify the imported files');
                return;
            end
            datafiles = [];

            if ~isempty(data) && numel(data) > 0 && ~isfield(data, 'datafiles')
                % old version of Agora which does not return the imported datafiles --> set all to imported (hack)
                for i = 1:length(state.files)
                    state.files(i).imported = true;
                end
                return;
            end
            
            for i = 1:length(data)
                datafiles = cat(1, datafiles, data(i).datafiles);
            end     
            ids = [datafiles.id];
            [~, i2] = unique(ids);
            datafiles = datafiles(i2);
                           
            target_names = cell(1, length(state.files));
            for i = 1:length(state.files)
                [~, name, ext] = fileparts(state.files(i).target);                    
                target_names{i} = [name, ext];
            end
            
            if state.verbose
                fprintf('\n\n');
                disp("verifying imports...")
            end
            step = max(10, ceil(length(datafiles) / 100));
            for i = 1:length(datafiles)
                
                if state.verbose && mod(i, step) == 0
                    self.print_progress(i/length(datafiles));
                end
                datafile = datafiles(i);
                [~, name, ext] = fileparts(datafile.name);
                datafile_name = [name, ext];
                indices = find(strcmp(target_names, datafile_name) & ~[state.files.imported]);                   
                if ~isempty(indices)
                    for index = indices
                        local_sha1 = sha1(state.files(index).file);
                        if strcmp(local_sha1, datafile.sha1)
                            state.files(index).imported = true;
                            break;
                        end
                    end
                end
            end
            if state.verbose
                self.print_progress(1);
                self.progress_string_length = [];
            end            
        end

        function print_progress(self, progress, appendix)
            if nargin < 3
                appendix = '';
            end
            len = 40;
            done = ceil(progress * len);
            bar = [repmat('o', 1, done), repmat('-', 1, len - done)];
            str = sprintf('%s %d%% %s', bar, ceil(progress * 100), appendix);
            if ~isempty(self.progress_string_length)
                backspaces = repmat('\b', [1 self.progress_string_length]);
                fprintf([backspaces]);
            end
            self.progress_string_length = length(str);            
            fprintf('%s', str);
        end  

        function print_final_message(self, state)
            if state.verbose
                nr_datafiles_imported = sum([state.files.imported]);
                success = all([state.files.uploaded] & [state.files.imported]);
                fprintf('\n\nImport complete:\n');
                fprintf('  Files Uploaded: %d, Files Imported: %d\n', numel(state.files), nr_datafiles_imported);
                if success
                    fprintf('\nAll files successfully imported.\n');
                else
                    fprintf('\nSome files were not imported:\n');
                    not_imported = state.files(~[state.files.imported]);
                    for f = not_imported
                        fprintf('  %s\n', f.file);
                    end
                end
                fprintf('\n');
            end
        end
    end

    methods (Hidden, Static)
        function [input_files, target_files] = prepare_path_to_upload(paths)
            if ischar(paths)
                paths = {paths};
            end
            input_files = {};
            target_files = {};
            
            for i = 1:length(paths)
                path = paths{i};
                if isfolder(path)
                    root = path;
                    filelist = dir(fullfile(path, '**/*.*'));
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
        end

        function val = check_zip_option(input_files)
            val = length(input_files) > 5;
        end
        
        function formatted_progress = pretty_print_progress(size1, size2)
            % Take two sizes in bytes and return them in a human-readable format.
            units = {'bytes', 'KB', 'MB', 'GB', 'TB'};
            for i = 1:numel(units)
                if size2 < 1024
                    formatted_progress = sprintf('%.1f/%.1f%s', size1, size2, units{i});
                    return;
                end
                size1 = size1 / 1024;
                size2 = size2 / 1024;
            end
            formatted_progress = sprintf('%.1f/%.1f PB', size1, size2);
        end

        function state = set_uploaded(state, files)
            for i = 1:length(files)
                file = files(i);
                id = file.id;
                index = find([state.files.id] == id);
                if ~isempty(index)
                    state.files(index).uploaded = true;
                end
            end
        end

    end
end

