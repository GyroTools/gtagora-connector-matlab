classdef Datafile < agora_connector.models.BaseModel & agora_connector.models.DownloadMixin
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/datafile/';                     
    end
    
    methods
        function final_path = download(self, path)
            final_path = fullfile(path, self.original_filename);
            folder = fileparts(final_path);                       
            if ~self.check_for_existing_file(final_path)
                [ ~, ~ ] = mkdir(folder);
                url = [self.BASE_URL, num2str(self.id), '/download/'];
                self.http_client.download(url, final_path);
            end            
        end
        
        function exists = check_for_existing_file(self, desired_path)
            exists = self.files_exists(desired_path, self.size, self.sha1);            
        end
    end
    
    methods (Static)
        function hashStr = get_sha1(path)
            engine = java.security.MessageDigest.getInstance('SHA-1');                       
            fid = fopen(path, 'rb');
            buffer_size = 1024*1024;
            while ~feof(fid)
                [data, count] = fread(fid, buffer_size, 'uint8=>uint8');
                if count > 0
                    engine.update(data);
                end                
            end
            fclose(fid);
            
            hash_uint8 = typecast(engine.digest, 'uint8');                        
            hash_hex = dec2hex(hash_uint8);            
            hashStr = '';
            nBytes = length(hash_hex);
            for k=1:nBytes
                hashStr(end+1:end+2) = lower(hash_hex(k,:));
            end
        end   
        function exists = files_exists(download_path, size, sha1)
            if exist(download_path, 'file')
                s = dir(download_path);         
                filesize = s.bytes;    

                if size == filesize && strcmp(agora_connector.models.Datafile.get_sha1(download_path), sha1)
                    exists = true;
                    return;
                end
            end
            
            exists = false;
        end
    end
end

