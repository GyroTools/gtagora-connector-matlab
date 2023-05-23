classdef DownloadInfo < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v1/downloadinfo/'        
    end

    methods    
        function df = to_datafile(self)
            import agora_connector.models.Datafile
            df = Datafile(self.http_client);
            df.addprop('id');
            df.id = self.id;
            df.addprop('original_filename');
            df.original_filename = self.filename;
            df.addprop('size');
            df.size = self.size;
            df.addprop('sha1');
            df.sha1 = self.sha1;
        end
    end
end

