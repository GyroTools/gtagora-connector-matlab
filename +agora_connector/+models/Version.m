classdef Version < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        
    end
    
    properties (Constant)
       BASE_URL = '/api/v1/version/'
    end
    
    methods 
        function self = Version(http_client)            
        end
        
        function dev = is_dev(self)
            dev = strcmpi(self.version, 'dev');
        end
        
        function result = is_higher_than(self, version)
            import agora_connector.utils.vercmp
        	result = vercmp(self.version, version) > 0;
        end
        
        function result = is_lower_than(self, version)
            import agora_connector.utils.vercmp
        	result = vercmp(self.version, version) < 0;
        end
        
        function needs(self, version, error_msg)
            if nargin < 3
                error_msg = '';
            end
            if ~self.is_dev() && self.is_lower_than(version)
                error(error_msg);
            end
        end
        
    end
end

