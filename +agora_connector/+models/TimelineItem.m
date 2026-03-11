classdef TimelineItem < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v2/timeline/'

        IDLE = 0
        STARTED = 1
        FINISHED = 2
        ERROR = 3
        CANCELING = 4
        CANCELED = 5
        QUEUED = 6
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
                self = self.get(self.id);
                if isfield(self.data, 'state')
                    state = self.data.state;
                    if state == self.IDLE || state == self.STARTED
                        pause(interval);
                        continue
                    elseif state == self.FINISHED
                        return;
                    elseif state == self.ERROR
                        error(self.data.error.message);
                    elseif state == self.CANCELING || state == self.CANCELED
                        return;
                    end
                else
                    return;
                end
            end
        end
    end
end

