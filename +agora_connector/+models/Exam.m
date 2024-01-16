classdef Exam < agora_connector.models.BaseModel & ... 
                agora_connector.models.DownloadDatasetMixin & ... 
                agora_connector.models.TaskResultsMixin & ... 
                agora_connector.models.SetNameMixin & ...
                agora_connector.models.TagMixin & ...
                agora_connector.models.RelationMixin
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/exam/';
        BASE_URL_V2 = '/api/v2/exam/';
    end
    
    methods                    
        function series = get_series(self)
            import agora_connector.models.Series
            series = Series;
            url = [self.BASE_URL, num2str(self.id), '/series/?limit=10000000000'];
            series = series.get_list(self.http_client, url);
        end
        
        function datasets = get_datasets(self)
            import agora_connector.models.Dataset
            datasets = [];
            series = self.get_series();
            for i = 1:length(series)
                datasets = [datasets, series(i).get_datasets()];
            end
            datasets = [datasets, self.get_files()];           
        end
        
        function datasets = get_files(self)
            import agora_connector.models.Dataset
            dataset = Dataset;
            url = [self.BASE_URL, num2str(self.id), '/files/?limit=10000000000'];                      
            datasets = dataset.get_list(self.http_client, url);            
        end       
    end
end

