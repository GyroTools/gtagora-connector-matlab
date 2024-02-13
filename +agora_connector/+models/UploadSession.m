classdef UploadSession
    properties
        progress_file
        state
        import_package
    end
    
    methods
        function self = UploadSession(http_client, paths, target_folder_id, progress_file, json_import_file, verbose, wait)
            import agora_connector.models.ImportPackage
            import agora_connector.models.UploadState

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
                verbose = true;
            end 
            if nargin < 6
                wait = true;
            end 
            
            self.progress_file = progress_file;
            if ~isempty(paths) && numel(paths) > 0
                import_package = ImportPackage(http_client).create();
                if exist('json_import_file', 'var') && ~isempty(json_import_file)
                    if ~exist(json_import_file, 'file')
                        error(['json_import_file ' json_import_file ' not found']);
                    end
                end

                if exist('progress_file', 'var') && ~isempty(progress_file) && ~isa(progress_file, 'char')
                    error('progress must be a Path selfect');
                end

                if exist('progress_file', 'var') && ~isempty(progress_file) && ~exist(progress_file, 'file')
                    [folder, ~, ~] = fileparts(progress_file);
                    if ~exist(folder, 'dir')
                        mkdir(folder);
                    end
                end

                state = import_package.create_state(paths, target_folder_id, json_import_file, wait, verbose);

                self.state = state;
                self.import_package = import_package;
            elseif exist('progress_file', 'var') && ~isempty(progress_file) && exist(progress_file, 'file')
                state = UploadState.from_file(progress_file);
                import_package = ImportPackage(http_client);
                import_package.get(state.import_package);                
                self.state = state;
                self.import_package = import_package;
            else
                error('Either a path list or an existing progress_file must be given as argument');
            end
        end
        
        function output = start(self)
            if self.import_package.is_complete
                disp('upload is finished');
                return;
            end
            output = self.import_package.upload_from_state(self.state, self.progress_file);
        end
    end
end