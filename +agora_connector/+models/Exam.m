classdef Exam < agora_connector.models.BaseModel & agora_connector.models.DownloadDatasetMixin & agora_connector.models.TaskResultsMixin
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/exam/';
        BASE_URL_V2 = '/api/v2/exam/';
    end
    
    methods     
        function self = set_name(self, name)
            url = [self.BASE_URL, num2str(self.id), '/'];
            data.name = name;
            response = self.http_client.put(url, data);  
            self.name = response.name;
        end
        
        function series = get_series(self)
            import agora_connector.models.Series
            series = Series(self.http_client);
            url = [self.BASE_URL, num2str(self.id), '/series/?limit=10000000000'];
            series = series.get_object_list(url);
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
            dataset = Dataset(self.http_client);
            url = [self.BASE_URL, num2str(self.id), '/files/?limit=10000000000'];                      
            datasets = dataset.get_object_list(url);            
        end

        function downloaded_files = download(self, path, flat)
            if nargin < 3
                flat = false;
            end
            if flat
                downloaded_files = download@agora_connector.models.DownloadDatasetMixin(self, path);
            else
                downloaded_files = [];
                files = self.get_files();
                for i = 1:length(files)
                    downloaded_files = [downloaded_files, files(i).download(path)];                    
                end
                series = self.get_series();
                for i = 1:length(series)
                    series_path = fullfile(path, self.remove_illegal_chars(series(i).name));                    
                    downloaded_files = [downloaded_files, series(i).download(series_path)];                     
                end
            end
        end
    end
end

