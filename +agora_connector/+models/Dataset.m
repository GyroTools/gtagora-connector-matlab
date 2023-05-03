classdef Dataset < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
    end
    
    properties (Constant)
        BASE_URL = '/api/v1/dataset/'
        BASE_URL_V2 = '/api/v2/dataset/'                
    end
    
    methods
        function datafiles = get_datafiles(self)
            import agora_connector.models.Datafile
            datafiles = [];
            if isprop(self, 'datafiles') && ~isempty(self.datafiles)    
                datafile = Datafile(self.http_client);
                datafiles = datafile.fill_from_data_array(self.datafiles);               
            end            
        end
    end
end

