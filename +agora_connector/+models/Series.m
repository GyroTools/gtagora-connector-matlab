classdef Series < agora_connector.models.BaseModel & agora_connector.models.DownloadDatasetMixin & agora_connector.models.TaskResultsMixin
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/serie/'
        BASE_URL_V2 = '/api/v2/series/'
    end
    
    methods    
        function datasets = get_datasets(self)
            import agora_connector.models.Dataset
            dataset = Dataset(self.http_client);
            url = [self.BASE_URL, num2str(self.id), '/datasets/?limit=10000000000'];
            datasets = dataset.get_object_list(url);
        end
    end
end

