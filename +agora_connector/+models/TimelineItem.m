classdef TimelineItem < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v2/timeline/'        
    end

    methods
        function self = join(self)
            self = self.poll();
        end
    end

    methods (Hidden)
        function self = poll(self, interval)
            if nargin < 2
                interval = 2;
            end            
            while true
                self = self.get_object(self.id);
                if isfield(self.data, 'state')
                    state = self.data.state;
                    if state == 0 || state == 1
                        pause(interval);                    
                        continue                    
                    elseif state == 2
                        return;
                    elseif state == 3
                        error(self.data.error.message);
                    elseif state == 4 || state == 5
                        return;
                    end
                else
                    return;
                end
            end                           
        end
    end
end

