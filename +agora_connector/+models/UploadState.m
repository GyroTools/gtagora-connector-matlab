classdef UploadState
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        import_package = [];
        files = [];
        target_folder_id = [];
        exam_id = [];
        series_id = [];
        json_import_file = [];
        relations = [];
        wait = true;
        verbose = false;
        timeout = [];
    end

    methods  
        function save(self, file)
            if ~isempty(file)
                json = jsonencode(self, PrettyPrint=true);
                fid = fopen(file, 'w');
                fwrite(fid, json);
                fclose(fid);
            end
        end
    end

    methods(Static)
        function state = from_file(file)
            import agora_connector.models.UploadFile
            import agora_connector.models.UploadState

            text = fileread(file);
            state_struct = jsondecode(text);
            if  isfield(state_struct, 'import_package') && ...
                    isfield(state_struct, 'files') && ...
                    isfield(state_struct, 'target_folder_id') && ...
                    isfield(state_struct, 'json_import_file') && ...
                    isfield(state_struct, 'wait') && ...
                    isfield(state_struct, 'verbose') && ...
                    isfield(state_struct, 'timeout')
                state = UploadState();
                files = arrayfun(@(x) UploadFile(), 1:length(state_struct.files));
                for i = 1:length(state_struct.files)
                    uf = UploadFile();
                    uf.id = state_struct.files(i).id;
                    uf.file = state_struct.files(i).file;
                    uf.target = state_struct.files(i).target;
                    uf.zip = state_struct.files(i).zip;
                    uf.size = state_struct.files(i).size;
                    uf.size_uploaded = state_struct.files(i).size_uploaded;
                    uf.nr_chunks = state_struct.files(i).nr_chunks;
                    uf.chunks_completed = state_struct.files(i).chunks_completed;
                    uf.identifier = state_struct.files(i).identifier;
                    uf.uploaded = state_struct.files(i).uploaded;
                    uf.imported = state_struct.files(i).imported;
                    files(i) = uf;
                end
                state.files = files;
                state.import_package = state_struct.import_package;                
                state.target_folder_id = state_struct.target_folder_id;
                state.exam_id = state_struct.exam_id;
                state.series_id = state_struct.series_id;
                state.json_import_file = state_struct.json_import_file;
                state.relations = state_struct.relations;
                state.wait = state_struct.wait;
                state.verbose = state_struct.verbose;
                state.timeout = state_struct.timeout;
                return
            else
                error('this is not a progress file');
            end
        end

        function val = is_progress_file(file)    
            val = false;
            try
                text = fileread(file);
                data = jsondecode(text);
                if  isfield(data, 'import_package') && ...
                    isfield(data, 'files') && ...
                    isfield(data, 'target_folder_id') && ...
                    isfield(data, 'json_import_file') && ...
                    isfield(data, 'wait') && ...
                    isfield(data, 'verbose') && ...
                    isfield(data, 'timeout')
                    val = true;
                end
            catch
                val = false;
            end
        end
    end
end