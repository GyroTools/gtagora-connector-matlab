classdef Project < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties        
    end
    
    properties (Constant)
        BASE_URL = '/api/v2/project/'
    end
    
    methods   
        function folder = get_root_folder(self)
            import agora_connector.models.Folder
            folder = Folder;
            folder = folder.get(self.root_folder, self.http_client);
        end
        
        function exams = get_exams(self)
            import agora_connector.models.Exam
            url = [self.BASE_URL, num2str(self.id), '/exam/?limit=10000000000'];
            exam = Exam(self.http_client);
            exams = exam.get_object_list(url);
        end
        
        function tasks = get_tasks(self)
            import agora_connector.models.Task
            url = [self.BASE_URL, num2str(self.id), '/task/?limit=10000000000'];
            task = Task(self.http_client);
            tasks = task.get_object_list(url);
        end
        
        function hosts = get_hosts(self)
            import agora_connector.models.Host
            url = [self.BASE_URL, num2str(self.id), '/host/?limit=10000000000'];
            host = Host(self.http_client);
            hosts = host.get_object_list(url);
        end
        
    end
end

