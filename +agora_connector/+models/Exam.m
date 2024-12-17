classdef Exam < agora_connector.models.BaseModel & ... 
                agora_connector.models.DownloadDatasetMixin & ... 
                agora_connector.models.TaskResultsMixin & ... 
                agora_connector.models.SetNameMixin & ...
                agora_connector.models.TagMixin & ...
                agora_connector.models.RelationMixin & ...
                agora_connector.models.FoldersMixin & ...
                agora_connector.models.ExportAexMixin
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
  
    properties (Constant)
        BASE_URL = '/api/v1/exam/';
        BASE_URL_V2 = '/api/v2/exam/';        
    end
    
    methods             
        function series = get_series(self, filters)
            import agora_connector.models.Series
            series = Series;
            url = [self.BASE_URL, num2str(self.id), '/series/?limit=10000000000'];
            if nargin > 1
                url = self.add_filter(url, filters);
            end
            series = series.get_list(self.http_client, url);
        end
        
        function datasets = get_datasets(self, filters)
            import agora_connector.models.Dataset
            dataset = Dataset;
            url = [self.BASE_URL, num2str(self.id), '/datasets/?limit=10000000000'];
            if nargin > 1
                url = self.add_filter(url, filters);
            end
            datasets = dataset.get_list(self.http_client, url);           
        end
        
        function datasets = get_files(self)
            import agora_connector.models.Dataset
            dataset = Dataset;
            url = [self.BASE_URL, num2str(self.id), '/files/?limit=10000000000'];                      
            datasets = dataset.get_list(self.http_client, url);            
        end    

        function patient = get_patient(self)
            import agora_connector.models.Patient
                       
            instance = Patient;
            patient = instance.fill_from_data(self.patient);                           
        end       
    end    
end

