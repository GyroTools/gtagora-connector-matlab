classdef ZipUploadFiles < handle
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties (Constant)
        MAX_FILE_LIMIT = 100*1024*1024;
        MAX_ZIP_FILE_SIZE = 2*1024*1024*1024;        
    end

    properties
        input_files = [];
        target_files = [];
    end

    properties (Hidden)
        zip_is_required = false;
    end

    methods
        function self = ZipUploadFiles(input_files)  
            self.input_files = input_files;                        
            self.zip_is_required = false;
        end

        function zip_files = create_zip(self, path, single_file, zip_filename)
            import agora_connector.models.UploadFile

            if nargin < 3
                single_file = false;
            end
            if nargin < 4
                zip_filename = [];
            end  

            [files_to_zip, root] = self.create_file_list(single_file);

            if ~self.zip_is_required
                zip_files = self.input_files;                
                return;
            end

            index = 0; 
            zip_id = 0;

            while ~isempty(files_to_zip)
                if isempty(zip_filename)
                    zip_filename = ['upload_', num2str(index), '.agora_upload'];
                end
                zip_path = fullfile(path, zip_filename);
                index = index + 1;                
                uf = UploadFile();
                uf.id = zip_id;
                uf.file = zip_path;
                uf.target = zip_filename;
                zip_files(zip_id + 1) = uf;    
                zip_id = length(zip_files);
                total_size = 0;                
                cur_files2zip = {};               

                while ~isempty(files_to_zip)
                    cur_file = files_to_zip{1};
                    files_to_zip(1) = [];
                    file = cur_file{1};                     
                    do_zip = cur_file{2};

                    if do_zip
                        cur_file_to_zip = strrep(strrep(file.file, '\', '/'), root, '');
                        cur_files2zip{end+1} = cur_file_to_zip;
                    else
                        uf = UploadFile();
                        uf.id = len(zip_files);
                        uf.file = file.file;
                        uf.target = file.target;
                        uf.size = file.size;
                        zip_files(zip_id + 1) = uf;
                        zip_id = length(zip_files);
                    end
                   

                    % here we should check the size of the zip file but
                    % matlab does not allow to write the zip file on the
                    % fly. Therefore we check the size of the uncompressed
                    % files                                                
                    total_size = total_size + file.size;
                    if total_size >  self.MAX_ZIP_FILE_SIZE
                        break;
                    end
                end
                if ~isempty(cur_files2zip)
                     zip(zip_path, cur_files2zip, root);
                     % the zip command automatically adds a .zip extension
                     movefile([zip_path, '.zip'], zip_path);

                     file_size = dir(zip_path);
                     file_size = file_size.bytes;
                     zip_files(zip_id).size = file_size;
                end                
            end
        end
    end

    methods (Hidden)
        function [file_list, root] = create_file_list(self, single_file)
            file_list = {};
            root = [];
            for i = 1:length(self.input_files)                
                in = [];
                if i <= length(self.input_files)
                    in = self.input_files(i);
                end                
                [file, do_zip] = self.create_entry(in, single_file);                
                if isempty(root)
                    root = strrep(strrep(file.file, '\', '/'), in.target, '');
                else
                    this_root = strrep(strrep(file.file, '\', '/'), in.target, '');
                    if ~strcmp(root, this_root)
                        error('the root directory must be the same for all files');
                    end
                end
                file_list{end+1} = {file, do_zip};
            end            
        end

        function [file, do_zip] = create_entry(self, file, single_file)
            do_zip = single_file;
            if ~do_zip            
                s = dir(file.file);         
                filesize = s.bytes; 
                do_zip = filesize < self.MAX_FILE_LIMIT;
            end

            if do_zip
                self.zip_is_required = true;
            end           
        end
    end
end