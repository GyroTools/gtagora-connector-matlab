classdef Connection
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        url = [];
        verify_certificate = true;
    end
    
    methods
        function self = Connection(url,verify_certificate)
            if nargin == 1
                verify_certificate = true;
            end
            self.url = url;
            self.verify_certificate = verify_certificate;            
        end
        
        function self = get_auth(self)
            error('Not Implemented');
        end
    end
end

