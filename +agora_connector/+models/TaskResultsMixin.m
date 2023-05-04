classdef (Abstract, HandleCompatible) TaskResultsMixin
    properties(Abstract,Constant)
        BASE_URL_V2;
    end

    methods
        function folders = get_task_results(self)
            import agora_connector.models.Folder
            url = [self.BASE_URL_V2, num2str(self.id), '/result_folders/'];
            folder = Folder(self.http_client);
            folders = folder.get_object_list(url);
        end
    end
end

