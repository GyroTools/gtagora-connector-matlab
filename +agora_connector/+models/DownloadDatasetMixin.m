classdef (Abstract, HandleCompatible) DownloadDatasetMixin   
    methods(Abstract)
        datasets = get_datasets(self);        
    end

    methods
        function downloaded_files = download(self, path)
            datasets = self.get_datasets();
            downloaded_files = {};
            for i = 1:length(datasets)
                downloaded_files = [downloaded_files, datasets(i).download(path)];
            end
        end       
    end
end

