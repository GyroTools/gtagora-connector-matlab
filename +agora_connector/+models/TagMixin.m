classdef (Abstract, HandleCompatible) TagMixin   
    properties(Abstract,Constant)
        BASE_URL;
    end
    
    methods
        function instance = tag(self, tag)
            import agora_connector.models.Tag
            import agora_connector.models.TagInstance
            
            if isa(tag, 'agora_connector.models.Tag')
                tag_id = tag.id;
            elseif isnumeric(tag)
                tag_id = tag;
            else
                error('The input must either be a tag or a tag id');
            end
            
            url = TagInstance.BASE_URL;
            data.tag_definition = tag_id;
            data.tagged_object_content_type = self.get_content_type();
            data.tagged_object_id = self.id;
            response = self.http_client.post(url, data);  
            instance = TagInstance(self.http_client);
            instance = instance.fill_from_data(response);
        end 

        function tags = get_tags(self)
            import agora_connector.models.Tag
            import agora_connector.models.TagInstance
            
            url = TagInstance.BASE_URL;
            if isprop(self,'project')
                url = strrep(url, '/tag-instance/', ['/project/', num2str(self.project), '/tag-instance/']);
            end
            response = self.http_client.get(url);  
            instance = TagInstance(self.http_client);
            instances = instance.fill_from_data_array(response);
            idx = 1;
            for i = 1:length(instances)
                if strcmpi(instances(i).tagged_object_content_type,self.get_content_type()) && instances(i).tagged_object_id == self.id
                    tag_instances(idx) = instances(i);
                    idx = idx + 1;
                end
            end  
                        
            if idx > 1 && ~isempty(tag_instances)
                idx = 1;
                tag = Tag;
                tag_definitions = tag.get_list(self.http_client);
                for i = 1:length(tag_instances)
                    for j = 1:length(tag_definitions)
                        if tag_definitions(j).id == tag_instances(i).tag_definition
                            tags(idx) = tag_definitions(j);
                            idx = idx + 1;
                            break;
                        end
                    end
                end
                return
            end

            tags = [];            
        end
    end
    
    methods(Abstract)
        type = get_content_type(self);        
    end
end

