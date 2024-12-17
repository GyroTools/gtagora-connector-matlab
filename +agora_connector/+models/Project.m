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

        function exams = get_exams(self, filters)
            import agora_connector.models.Exam            
            url = [self.BASE_URL, num2str(self.id), '/exam/?limit=10000000000'];
            if nargin > 1
                url = self.add_filter(url, filters);
            end
            exam = Exam;
            exams = exam.get_list(self.http_client, url);
        end

        function exams = get_exams_for_tag(self, tag)
            import agora_connector.models.Exam
            tag_id = self.get_tag_id(tag);
            url = [self.BASE_URL, num2str(self.id), '/exam/for_tag/',  num2str(tag_id), '/'];
            exam = Exam;
            exams = exam.get_list(self.http_client, url);
        end

        function series = get_series_for_tag(self, tag)
            import agora_connector.models.Series
            tag_id = self.get_tag_id(tag);
            url = [self.BASE_URL, num2str(self.id), '/series/for_tag/',  num2str(tag_id), '/'];
            serie = Series;
            series = serie.get_list(self.http_client, url);
        end

        function datasets = get_datasets_for_tag(self, tag)
            import agora_connector.models.Dataset
            tag_id = self.get_tag_id(tag);
            url = [self.BASE_URL, num2str(self.id), '/dataset/for_tag/',  num2str(tag_id), '/'];
            dataset = Dataset;
            datasets = dataset.get_list(self.http_client, url);
        end

        function patients = get_patients_for_tag(self, tag)
            import agora_connector.models.Patient
            tag_id = self.get_tag_id(tag);
            url = [self.BASE_URL, num2str(self.id), '/patient/for_tag/',  num2str(tag_id), '/'];
            patient = Patient;
            patients = patient.get_list(self.http_client, url);
        end

        function tags = get_tags(self)
            import agora_connector.models.Tag
            url = [self.BASE_URL, num2str(self.id), '/tag-definition/'];
            tag = Tag;
            tags = tag.get_list(self.http_client, url);
        end

        function tasks = get_tasks(self)
            import agora_connector.models.Task
            url = [self.BASE_URL, num2str(self.id), '/task/?limit=10000000000'];
            task = Task;
            tasks = task.get_list(self.http_client, url);
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
                task = task.get(name_or_id);
            end
        end

        function hosts = get_hosts(self)
            import agora_connector.models.Host
            url = [self.BASE_URL, num2str(self.id), '/host/?limit=10000000000'];
            host = Host;
            hosts = host.get_list(self.http_client, url);
        end

        function members = get_members(self)
            import agora_connector.models.Member
            import agora_connector.models.ProjectRole
            import agora_connector.models.User

            if isempty(self.memberships)
                members = [];
                return;
            end
            members(length(self.memberships)) = Member;

            roles = ProjectRole;
            roles = roles.get_list(self.http_client);

            for i = 1:length(self.memberships)
                user = User(self.http_client);
                user = user.get(self.memberships(i).user);
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
                roles = ProjectRole;
                roles = roles.get_list(self.http_client);
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

        function results = search(self, search_string, result_type)
            import agora_connector.models.SearchResult

            if nargin < 3
                result_type = 0;
            end
            params = SearchResult.get_url_params(search_string, result_type);
            url = [self.BASE_URL, num2str(self.id), '/fulltext/', params];
            results = SearchResult;
            results = results.get_list(self.http_client, url, 60);
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

    methods( Static )
        function tag_id = get_tag_id(tag)
            if isa(tag, 'agora_connector.models.Tag')
                tag_id = tag.id;
            elseif isnumeric(tag) && floor(tag) == tag
                tag_id = tag;
            else
                error('the tag must eighet be a "Tag" class or a tag ID');
            end
        end
    end
end

