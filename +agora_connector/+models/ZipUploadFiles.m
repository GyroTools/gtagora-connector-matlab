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
        function self = ZipUploadFiles(input_files, target_files)  
            self.input_files = input_files;            
            if nargin > 1 && ~isempty(target_files)
                self.target_files = target_files;
            end
            self.zip_is_required = false;
        end

        function [input_files, target_files] = create_zip(self, path)  
            [files_to_zip, root] = self.create_file_list();
            if ~self.zip_is_required
                input_files = self.input_files;
                target_files = self.target_files;
                return;
            end

            index = 0;
            input_files = {};
            target_files = {};            

            while ~isempty(files_to_zip)
                zip_filename = ['upload_', num2str(index), '.agora_upload'];
                zip_path = fullfile(path, zip_filename);
                 index = index + 1;
                input_files{end+1} = zip_path;
                target_files{end+1} = zip_filename;
                total_size = 0;                
                cur_files2zip = {};               

                while ~isempty(files_to_zip)
                    cur_file = files_to_zip{1};
                    files_to_zip(1) = [];
                    file = cur_file{1};                     
                    do_zip = cur_file{3};

                    if do_zip
                        cur_files2zip{end+1} = file;
                    else
                        target_file = cur_file{2};
                        input_files{end+1} = file;
                        target_files{end+1} = target_file;
                    end
                   

                    % here we should check the size of the zip file but
                    % matlab does not allow to write the zip file on the
                    % fly. Therefore we check the size of the uncompressed
                    % files
                    s = dir(file);                              
                    total_size = total_size + s.bytes;
                    if total_size >  self.MAX_ZIP_FILE_SIZE
                        break;
                    end
                end
                if ~isempty(cur_files2zip)
                     zip(zip_path, cur_files2zip, root);
                     % the zip command automatically adds a .zip extension
                     movefile([zip_path, '.zip'], zip_path);
                end
            end
        end
    end

    methods (Hidden)
        function [file_list, root] = create_file_list(self)
            file_list = {};
            root = [];
            for i = 1: max(length(self.input_files), length(self.target_files))
                in = [];
                if i <= length(self.input_files)
                    in = self.input_files{i};
                end
                target = [];
                if i <= length(self.target_files)
                    target = self.target_files{i};
                end
                [file, target_file, do_zip] = self.create_entry(in, target);                
                if isempty(root)
                    root = strrep(file, target_file, '');
                else
                    this_root = strrep(file, target_file, '');
                    if ~strcmp(root, this_root)
                        error('the root directory must be the same for all files');
                    end
                end
                file_list{end+1} = {file, target_file, do_zip};
            end
        end

        function [file, target_file, do_zip] = create_entry(self, file, target_file)
            s = dir(file);         
            filesize = s.bytes; 
            do_zip = filesize < self.MAX_FILE_LIMIT;

            if do_zip
                self.zip_is_required = true;
            end           
        end
    end
end