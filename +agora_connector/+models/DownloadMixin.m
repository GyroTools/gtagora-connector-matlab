classdef (Abstract, HandleCompatible) DownloadMixin   
    methods(Abstract)
        downloaded_files = download(self, path);        
    end
end

