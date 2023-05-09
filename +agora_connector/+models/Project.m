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

        function task = get_task(self, name_or_id)
            import agora_connector.models.Task
            if ischar(name_or_id)
                tasks = self.get_tasks();
                for i = 1:length(tasks)
                    if strcmp(tasks(i).name, name_or_id)
                        task = tasks(i);
                        return;
                    end
                    error('task not found');
                end
            else              
                task = Task(self.http_client);
                task = task.get_object(name_or_id);
            end

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

        function items = get_trash(self)
            import agora_connector.models.Trash
            trash = Trash(self.http_client);
            items = trash.get_items(self.id);
        end

        function empty_trash(self)
            import agora_connector.models.Trash
            trash = Trash(self.http_client);
            trash.empty(self.id);
        end
        
    end
end

