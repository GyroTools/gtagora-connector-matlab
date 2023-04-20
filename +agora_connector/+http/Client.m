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
    end
end

