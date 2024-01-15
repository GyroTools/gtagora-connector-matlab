classdef FolderItem < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/folderitem/';
    end
    
    methods  
        function self = fill_from_data(self, data)
            fill_from_data@agora_connector.models.BaseModel(self, data);      
            cls = self.content_type;
            if ~isempty(cls)
                cls(1) = upper(cls(1));
                if strcmp(cls, 'Serie')
                    cls = 'Series';
                end
                obj = agora_connector.models.(cls)(self.http_client);
                obj.fill_from_data(self.content_object);
                self.content_object = obj;
            end
        end
    end
end

