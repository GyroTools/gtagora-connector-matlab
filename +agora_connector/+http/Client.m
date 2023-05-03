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
            url = [self.connection.url, url];            
            auth = self.connection.get_auth();
            
            if ~self.connection.verify_certificate
                options = weboptions('CertificateFilename','');
            else
                options = weboptions;
            end                               
            options.Timeout = timeout;
            options.MediaType = 'application/json';
            options = auth.add(options);
            
            response = webread(url, options);
        end
        
        function response = post(self, url, data, timeout)
            if nargin < 3
                data = [];
            end
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
            options.Timeout = timeout;
            options.MediaType = 'application/json';
            options = auth.add(options);
            
            response = webwrite(url, data, options);            
        end
        
        function response = put(self, url, data, timeout)            
            if nargin < 3
                data = [];
            end
            if nargin < 4
                timeout = self.TIMEOUT;
            end
            
            request = self.get_base_request(data, matlab.net.http.RequestMethod.PUT);
            resp = self.send_request(url, request, timeout);                        
            response = resp.Body.Data;
        end
        
        function request = get_base_request(self, data, method)
            if nargin < 2
                data = [];
            end                        
            body = matlab.net.http.MessageBody(data);
            contentTypeField = matlab.net.http.field.ContentTypeField('application/json');
            type = matlab.net.http.MediaType('application/json','q','.5');
            acceptField = matlab.net.http.field.AcceptField(type);
            
            auth = self.connection.get_auth();
            authField = auth.get_field();  
                                    
            header = [acceptField contentTypeField authField];           
            request = matlab.net.http.RequestMessage(method,header,body);                        
        end
        
        function resp = send_request(self, url, request, timeout)            
            if nargin < 4
                timeout = self.TIMEOUT;
            end            
            options = matlab.net.http.HTTPOptions('ConnectTimeout', timeout);                        
            uri = matlab.net.URI([self.connection.url, url]);                                                                       
            resp = request.send(uri, options);
                                    
            sc = resp.StatusCode;
            if sc ~= matlab.net.http.StatusCode.OK
                error([getReasonPhrase(getClass(sc)),': ',getReasonPhrase(sc)])                
            end                        
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
    end
end

