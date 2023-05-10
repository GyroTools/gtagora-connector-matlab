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
    end
    
    methods(Abstract)
        type = get_content_type(self);        
    end
end

