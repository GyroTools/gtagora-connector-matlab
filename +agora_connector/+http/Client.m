classdef Client
    %UNTITLED7 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        connection = [];
    end
    
    properties (Constant)
        TIMEOUT = 20
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
            response = webwrite(url, options);     
        end
                               
        function download(self, url, target_filename)            
            url = [self.connection.url, url];            
            auth = self.connection.get_auth();
            
            if ~self.connection.verify_certificate
                options = weboptions('CertificateFilename','');
            else
                options = weboptions;
            end                                          
            options.MediaType = 'application/json';
            options = auth.add(options);                                               
            websave(target_filename, url, options);
        end

%         function response = upload(self, url, input_files, target_files, timeout) 
%             import agora_connector.http.ConnectionLegacy
%             import agora_connector.http.ClientLegacy
% 
%             if nargin < 5
%                 timeout = [];
%             end
% 
%             auth = self.connection.get_auth();
%             full_url = [self.connection.url, url];
%             connections_legacy = ConnectionLegacy(self.connection.url, auth.api_key);
%             response = ClientLegacy.Upload(full_url, input_files, target_files, connections_legacy, timeout);
%         end

        function upload(self, url, input_files, target_files, timeout)             
            if nargin < 5
                timeout = self.TIMEOUT;
            end
                                   
            if ~iscell(input_files)
                input_files = {input_files};
            end
            if ~iscell(target_files)
                target_files = {target_files};
            end
            if length(target_files) ~= length(input_files)
                error('input_files and target_files must have the same length');
            end
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
            
            for i = 1:length(input_files)                
                fid = fopen(input_files{i});
                if fid == -1                    
                    error(['Cannot open file = ', input_files{i}]);
                end
                fseek(fid, 0, 'eof');
                filesize = ftell(fid);
                fseek(fid, 0, 'bof');
                nr_chunks = ceil(filesize/chunk_size);
                                
                filename = target_files{i};
                uid = char(java.util.UUID.randomUUID);                              
                    
                for cur_chunk = 1:nr_chunks                   
                    d = fread(fid,chunk_size,'*uint8'); % Read in byte stream    

                    body=struct;
                    body.description = '';
                    body.flowChunkNumber = num2str(cur_chunk);
                    body.flowChunkSize = num2str(chunk_size);
                    body.flowCurrentChunkSize = num2str(length(d));
                    body.flowTotalSize = num2str(filesize);
                    body.flowIdentifier = uid;
                    body.flowFilename = filename;
                    body.flowRelativePath = filename;
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
                    req.send(uri, options);
                end
                fclose(fid);
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

