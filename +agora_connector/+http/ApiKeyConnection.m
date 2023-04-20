classdef ApiKeyConnection < agora_connector.http.Connection
    %UNTITLED4 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        api_key = [];
    end
    
    methods
        function self = ApiKeyConnection(url, api_key,verify_certificate)            
            if nargin == 2
                verify_certificate = true;
            end
            self@agora_connector.http.Connection(url, verify_certificate);
            self.api_key = api_key;
        end
        
        function auth = get_auth(self)
            auth = agora_connector.http.ApiKeyAuth(self.api_key);
        end
    end
end

