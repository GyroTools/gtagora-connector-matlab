classdef Folder < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/folder/'
    end
    
    methods  
        function folder = create(self, name)
            url = [self.BASE_URL, num2str(self.id), '/new/'];
            data = struct;
            data.name = name;
            response = self.http_client.post(url, data);            
            if isfield(response, 'content_object')
                folder = agora_connector.models.Folder;
                folder = folder.fill_from_data(response.content_object);
            end       
        end
        
        function folder = get_or_create(self, path)
            next_folder = self;
            
            p = path;
            while p ~= '\'
                [p, cur] = fileparts(p);
                next_folder_exists = false;
            end          
        end
    end
end

