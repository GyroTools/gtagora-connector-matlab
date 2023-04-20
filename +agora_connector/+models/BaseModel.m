classdef BaseModel < dynamicprops
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        http_client = [];
    end        
    
    methods
        function self = BaseModel(http_client)
            if nargin > 0
                self.http_client = http_client;
            end
        end
        
        function self = get(self, id, http_client)
            if nargin < 2
                id = [];
            end
            if nargin < 3
                http_client = [];
            end
            self.http_client = http_client;
            self = self.get_object(id);
        end
    end
    
    methods (Hidden)
        function self = get_object(self, id)
            if nargin < 2
                id = [];
            end
            if ~isempty(id)
                url = [self.BASE_URL, num2str(id), '/'];            
            else
                url = self.BASE_URL;
            end

            data = self.http_client.get(url);       
            fn = fieldnames(data);
            for i = 1:length(fn)
                self.addprop(fn{i});
                self.(fn{i}) = data.(fn{i});
            end
        end
    end
end

