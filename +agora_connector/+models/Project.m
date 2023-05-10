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
        
        function members = get_members(self)
            import agora_connector.models.Member
            import agora_connector.models.ProjectRole
            import agora_connector.models.User
            
            members(length(self.memberships)) = Member;
            
            roles = ProjectRole(self.http_client);
            roles = roles.get_object_list(roles.BASE_URL);
                
            for i = 1:length(self.memberships)
                user = User(self.http_client);
                user = user.get_object(self.memberships(i).user);                                                
                members(i).user = user;
                role = [];
                for j = 1:length(roles)
                    if roles(j).id == self.memberships(i).role
                        role = roles(j);
                        break;
                    end
                end
                members(i).role = role;
            end
        end
        
        function add_member(self, user, role)
            import agora_connector.models.ProjectRole
            
            if isa(user, 'agora_connector.models.User')
                user_id = user.id;
            elseif isnumeric(tag)
                user_id = user;
            else
                error('The user must either be a User class or an id');
            end
            
            if isa(user, 'agora_connector.models.ProjectRole')
                role_id = role.id;
            elseif isnumeric(role)
                role_id = role;                
            elseif ischar(role)
                roles = ProjectRole(self.http_client);
                roles = roles.get_object_list(roles.BASE_URL);
                role_id = [];
                for j = 1:length(roles)
                    if strcmpi(roles(j).name, role)
                        role_id = roles(j).id;
                        break;
                    end
                end
                if isempty(role_id)
                    error(['role "', role, '" not found']);
                end
            else
                error('The role must either be a ProjectRole class, an id or a string');
            end
            
            url = '/api/v2/projectmembership/';            
            data.project = self.id;
            data.role = role_id;
            data.user = user_id;
            
            self.http_client.post(url, data, 60);
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

