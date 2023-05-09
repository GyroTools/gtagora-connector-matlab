classdef Trash < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v1/trash/'
    end

    methods
        function items = get_items(self, project_id)
            all_items = self.get_list(self.http_client);            
            j = 1;
            for i = 1:length(all_items)
                if all_items(i).project == project_id
                    items(j) = all_items(i);
                    j = j + 1;
                end
            end
            if j == 1
                items = [];
            end
        end

        function empty(self, project_id)
            items = self.get_items(project_id);
            for i = 1:length(items)
                url = [self.BASE_URL, num2str(items(i).id), '/delete'];
                self.http_client.delete(url, 60);   
            end
        end
    end
end

