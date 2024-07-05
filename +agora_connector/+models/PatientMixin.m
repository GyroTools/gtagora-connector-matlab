classdef (Abstract, HandleCompatible) PatientMixin   
    properties(Abstract,Constant)
        BASE_URL;
    end
    
    methods
        function patient = get_patient(self)
            import agora_connector.models.Patient
            
            patient = [];
            url = [self.BASE_URL_V2, num2str(self.id), '/patient/'];
            
            try
                response = self.http_client.get(url);
            catch
                return;
            end
            if ~isempty(response)
                instance = Patient;
                patient = instance.fill_from_data(response);                
            end            
        end
    end
    
    methods(Abstract)
        type = get_content_type(self);        
    end
end

