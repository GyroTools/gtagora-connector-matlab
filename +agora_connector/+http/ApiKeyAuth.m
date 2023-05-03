classdef ApiKeyAuth < agora_connector.http.AuthBase
    properties
        api_key = '';
    end
    
    methods
        function self = ApiKeyAuth(api_key)
            self.api_key = api_key;
        end
        
        function options = add(self, options)
            options.KeyName = 'Authorization';
            options.KeyValue = ['X-Agora-Api-Key ', self.api_key];
        end
        
        function field = get_field(self)
            field = matlab.net.http.field.AuthorizationField('Authorization',['X-Agora-Api-Key ', self.api_key]);
        end
    end
end

