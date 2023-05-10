classdef (Abstract, HandleCompatible) TaskResultsMixin
    properties(Abstract,Constant)
        BASE_URL_V2;
    end

    methods
        function folders = get_task_results(self)
            import agora_connector.models.Folder
            url = [self.BASE_URL_V2, num2str(self.id), '/result_folders/'];
            folder = Folder;
            folders = folder.get_list(self.http_client, url);
        end
    end
end

