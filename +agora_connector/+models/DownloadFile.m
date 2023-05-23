classdef DownloadFile < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v1/downloadfile/'           
    end

    methods        
    end

    methods (Static)
        function url = project_url(id)
            url = ['/api/v1/project/', num2str(id),'/downloadfile/'];
        end
    end
end

