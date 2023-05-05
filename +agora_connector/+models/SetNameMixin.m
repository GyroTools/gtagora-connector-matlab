classdef (Abstract, HandleCompatible) SetNameMixin   
    properties(Abstract,Constant)
        BASE_URL;
    end
    
    methods
        function self = set_name(self, name)
            url = [self.BASE_URL, num2str(self.id), '/'];
            data.name = name;
            if isprop(self, 'id')
                data.id = self.id;
            end
            if isprop(self, 'project')
                data.project = self.project;
            end
            response = self.http_client.put(url, data);  
            self.name = response.name;
        end    
    end
end

