classdef (Abstract, HandleCompatible) FoldersMixin   
    properties(Abstract,Constant)
        BASE_URL;
    end
    
    methods
        function folders = get_folders(self)
            import agora_connector.models.Folder
            
            folders = [];
            url = [self.BASE_URL_V2, num2str(self.id), '/folders/'];
            
            try
                response = self.http_client.get(url);
            catch
                return;
            end
            if ~isempty(response)
                instance = Folder;
                folders = instance.fill_from_data_array(response);                
            end            
        end
    end       
end

