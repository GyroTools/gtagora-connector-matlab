classdef (Abstract, HandleCompatible) ExamMixin   
    properties(Abstract,Constant)
        BASE_URL;
    end
    
    methods
        function exam = get_exam(self)
            import agora_connector.models.Exam
            
            exam = [];
            url = [self.BASE_URL_V2, num2str(self.id), '/exam/'];
            
            try
                response = self.http_client.get(url);
            catch
                return;
            end
            if ~isempty(response)
                instance = Exam;
                exam = instance.fill_from_data(response);                
            end            
        end
    end       
end

