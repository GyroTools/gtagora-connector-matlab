classdef Client
    %UNTITLED7 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        connection = [];
    end
    
    properties (Constant)
        TIMEOUT = 20
        UPLOAD_CHUCK_SIZE = 100 * 1024 * 1024;
    end
    
    methods
        function self = Client(connection)
            self.connection = connection;
        end  
        
        function success = check_connection(self)
            try
                response = self.get('/api/v1/user/current/');
                success = true;
            catch
                success = false;
            end                    
        end  
        
        function response = get(self, url, timeout)
            if nargin < 3
                timeout = self.TIMEOUT;
            end

            options = self.get_options(timeout);
            url = self.get_url(url);                      
            response = webread(url, options);
        end
        
        function response = post(self, url, data, timeout)
            if nargin < 3 || isempty(data)
                data = struct;
            end
            if nargin < 4
                timeout = self.TIMEOUT;
            end

            options = self.get_options(timeout);
            url = self.get_url(url);
            response = webwrite(url, data, options);          
        end

        function response = put(self, url, data, timeout)
            if nargin < 3
                data = struct;
            end
            if nargin < 4
                timeout = self.TIMEOUT;
            end

            options = self.get_options(timeout, 'put');
            url = self.get_url(url);
            response = webwrite(url, data, options);     
        end

        function response = delete(self, url, timeout)            
            if nargin < 3
                timeout = self.TIMEOUT;
            end

            options = self.get_options(timeout, 'delete');
            url = self.get_url(url);
            response = webwrite(url, struct, options);     
        end
                               
        function download(self, url, target_filename, timeout)  
            if nargin < 4
                timeout = self.TIMEOUT;
            end

            url = [self.connection.url, url];            
            auth = self.connection.get_auth();
            
            if ~self.connection.verify_certificate
                options = weboptions('CertificateFilename','');
            else
                options = weboptions;
            end                                          
            options.MediaType = 'application/json';
            options = auth.add(options);
            options.Timeout = timeout;
            websave(target_filename, url, options);
        end

        function upload(self, url, files, timeout, progress_callback)             
            import agora_connector.utils.sha256

            if nargin < 4
                timeout = self.TIMEOUT;
            end  
            if nargin < 5
                progress_callback = [];
            end 
            max_retries = 5;
            url = self.get_url(url);
            chunk_size = self.get_upload_chunk_size();    

            BOUNDARY = '***********************';
            EOL = sprintf('%s%s',[13, 10]);
            content_type_field = matlab.net.http.field.ContentTypeField(matlab.net.http.MediaType('multipart/form-data', 'boundary', BOUNDARY));
            auth_field = self.connection.get_auth().get_field();
            type = matlab.net.http.MediaType('application/json');
            acceptField = matlab.net.http.field.AcceptField(type);
            header = [content_type_field, auth_field, acceptField];
            uri = matlab.net.URI(url);
            
            for i = 1:length(files)   
                file = files(i);
                fid = fopen(file.file);
                if fid == -1                    
                    error(['Cannot open file = ', file.file]);
                end
                fseek(fid, 0, 'eof');
                filesize = ftell(fid);
                fseek(fid, 0, 'bof');
                nr_chunks = ceil(filesize/chunk_size);
                                
                [~, stem, ext] = fileparts(file.file);
                filename = [stem, ext];
                target_filename = file.target;
                if isempty(file.identifier)
                    uid = char(java.util.UUID.randomUUID);  
                    file.identifier = uid;
                else
                    uid = file.identifier;
                end

                start_chunk = 1;
                if ~isempty(file.chunks_completed)
                    start_chunk = file.chunks_completed+1;
                end
                if start_chunk > 1
                    fseek(fid, (start_chunk-1) * self.UPLOAD_CHUCK_SIZE, 'bof');
                end
                    
                for cur_chunk = start_chunk:nr_chunks
                    retry_count = 0;
                    while retry_count < max_retries
                        try
                            if ~isempty(progress_callback)
                                progress_callback(file);
                            end                            
                            d = fread(fid,chunk_size,'*uint8'); % Read in byte stream

                            body=struct;
                            body.description = '';
                            body.flowChunkNumber = num2str(cur_chunk);
                            body.flowChunkSize = num2str(chunk_size);
                            body.flowCurrentChunkSize = num2str(length(d));
                            body.flowTotalSize = num2str(filesize);
                            body.flowIdentifier = uid;
                            body.flowFilename = target_filename;
                            body.flowRelativePath = target_filename;
                            body.flowTotalChunks = num2str(nr_chunks);

                            % the following code is probably a bit too complicated
                            % but it's the only way I found which worked.
                            % The workflow is the following:
                            %   1. create a string called data
                            %   2. add the form fields as string to data
                            %   3. convert the string to binary (uint8) and add the
                            %      file chunk as binary
                            %   4. finalize the data with the termination string
                            %   5. create a MessageBody object with the binary data
                            %   6. create a request with the body and send it
                            data = '';
                            fn = fieldnames(body);
                            for j = 1:length(fn)
                                data = [data, ...
                                    '--', BOUNDARY, EOL, ...
                                    'Content-Disposition: form-data; name="',fn{j},'"', EOL, EOL, ...
                                    body.(fn{j}), EOL ];
                            end
                            data = [data, ...
                                '--', BOUNDARY, EOL,...
                                'Content-Disposition: form-data; name="file"; filename="', filename, '"', EOL,...
                                'Content-Type: application/octet-stream',EOL,...
                                EOL];

                            data = [uint8(data), d'];
                            finalize_str = [EOL, '--', BOUNDARY, '--', EOL];
                            data = [data, uint8(finalize_str)];
                            body = matlab.net.http.MessageBody;
                            body.Payload = data;

                            req = matlab.net.http.RequestMessage('POST', header, body);
                            options = matlab.net.http.HTTPOptions('ConnectTimeout', timeout);
                            if ~self.connection.verify_certificate
                                options.CertificateFilename = '';
                            end
                            req.send(uri, options);
                            break;
                        catch
                            retry_count = retry_count + 1;
                            delay = 2^retry_count;                                                       
                            pause(delay);
                        end
                    end
                    if retry_count == max_retries
                        error(['Failed to upload chunk ', num2str(chunk), ' after ', num2str(max_retries), ' retries.']);
                    end

                    file.chunks_completed = cur_chunk;
                    file.size_uploaded = file.size_uploaded + length(d);

                    if ~isempty(progress_callback)
                        progress_callback(file);
                    end
                end
                fclose(fid);
                
                hash_local = sha256(file.file);
                hash_server = [];                
                while isempty(hash_server)
                    try
                        data = self.get(['/api/v1/flowfile/' uid '/']);
                    catch
                        error('Failed to get the hash of the file from the server');
                    end                                        
                    if data.state == 2                       
                        hash_server = data.content_hash;
                        if ~strcmp(hash_local, hash_server)
                            continue;
                        else                           
                             file.uploaded = true;
                             file.size_uploaded = file.size;
                             if ~isempty(progress_callback)
                                 progress_callback(file);
                             end
                            break;
                        end
                    elseif data.state == 3 || data.state == 5
                        error(['Failed to upload ' cur_file ': there was an error joining the chunks']);
                    end                    
                end                         
            end                     
        end
    end

    methods (Hidden)        
        function options = get_options(self, timeout, type)                                  
            if nargin < 2
                timeout = self.TIMEOUT;
            end
            if nargin < 3
                type = [];
            end              
            auth = self.connection.get_auth();            
            options = weboptions;
            if ~self.connection.verify_certificate
                options.CertificateFilename = '';            
            end     
            if ~isempty(type)
                options.RequestMethod = type;
            end
            options.Timeout = timeout;
            options.MediaType = 'application/json';
            options = auth.add(options);                                       
        end

        function url = get_url(self, url)
            url = [self.connection.url, url];    
        end
    end

    methods (Hidden, Static)
        function chunk_size = get_upload_chunk_size()
            heap_space = java.lang.Runtime.getRuntime.maxMemory;
            heap_space_mb = heap_space /1024/1024;
            if heap_space_mb < 500
                chunk_size = 8*1024*1024;
            elseif heap_space_mb < 900
                chunk_size = 50*1024*1024;
            else
                chunk_size = 100*1024*1024;
            end
        end        
    end
end

