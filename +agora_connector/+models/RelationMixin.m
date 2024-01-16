classdef (Abstract, HandleCompatible) RelationMixin
    properties(Abstract,Constant)
        BASE_URL;
    end

    methods
        function relations = relations(self)
            url = [self.BASE_URL, num2str(self.id), '/datarelations/'];
            response = self.http_client.get(url);
            if ~isempty(response)
                instance = feval(class(self));
                rels = instance.fill_from_data_array(response);
                idx = 1;
                if ~isempty(rels)
                    for i = 1:length(rels)
                        if rels(i).from_object.object_id ~= self.id
                            object = rels(i).from_object;
                        else
                            object = rels(i).to_object;
                        end
                        cls = object.content_type;
                        if ~isempty(cls)
                            cls(1) = upper(cls(1));
                            if strcmp(cls, 'Serie')
                                cls = 'Series';
                            end
                            instance = agora_connector.models.(cls)(self.http_client);
                            instance.get(object.object_id, self.http_client);
                            relations(idx) = instance;
                            idx = idx + 1;
                        end
                    end
                    return;
                end
            end
            relations = [];
        end
    end

    methods(Abstract)
        type = get_content_type(self);
    end
end

