classdef Workbook < agora_connector.models.BaseModel
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
    end

    properties (Constant)
        BASE_URL = '/api/v2/workbook/'
    end

    methods (Hidden) 
        function self = decode_masks(self)
            if isprop(self, 'mask')                    
                for i = 1:length(self.mask)
                    cm = self.mask.mMasks(i);
                    mask = zeros(cm.mSizeX, cm.mSizeY, cm.mSizeZ, cm.mSizeT, 'uint8');
                    len = cm.mSliceSize;
                    for s = 1:length(cm.mSliceMask)
                        sm = self.mask.mMasks(i).mSliceMask(s).mBase64Values;
                        if ~isempty(sm)
                            m = self.decode_mask(sm, len);
                            mask(:,:,s) = reshape(m, cm.mSizeX, cm.mSizeY)';
                        end
                    end
                    self.mask.mMasks(i).data = mask;
                end                
            end            
        end
    end

    methods(Static, Hidden)        
        function mask = decode_mask(b64mask, len)
            MaskTypeEmpty = 0;
            MaskTypeFilled = 1;
            MaskTypeBitmask1 = 2;
            MaskTypeBitmask2 = 3;
            MaskTypeBitmask3 = 4;
            MaskTypeByteArray = 5;
            MaskTypeRegular1 = 6;
            MaskTypeRegular2 = 7;
            MaskTypeRegular3 = 8;
            
            
            encoded_mask = agora_connector.models.Workbook.base64decode(b64mask);
            
            mask = zeros(len, 1, 'uint8');
            if ~isempty(encoded_mask)
                type = encoded_mask(1);
                [nr_bytes, shifts] = agora_connector.models.Workbook.get_nr_bytes(type);
                switch type
                    case MaskTypeEmpty
                        return;
                    case MaskTypeFilled
                        mask(:) = 1;
                        return;
                    case MaskTypeByteArray
                        mask(:) = encoded_mask(2:len+1);
                    case {MaskTypeBitmask1, MaskTypeBitmask2, MaskTypeBitmask3}                    
                        label = encoded_mask(2);
                        target_index = bitshift(uint32(encoded_mask(3)), 16) + bitshift(uint32(encoded_mask(4)), 8) + uint32(encoded_mask(5));
                        target_index = target_index + 1;
                        source_index = 6;                     
                        entries = (length(encoded_mask) - 5) / nr_bytes;       
                        
                        indices = source_index:source_index + nr_bytes*entries - 1;
                        values = encoded_mask(indices);               
                        run_lengths_target_inds = zeros(1, entries, 'uint32');
                        for b = 1:nr_bytes
                            shift = shifts(b);
                            run_lengths_target_inds = run_lengths_target_inds + bitshift(uint32(values(b:nr_bytes:end)), shift);
                        end       
                        run_lengths = run_lengths_target_inds(1:2:end);
                        target_index_increment = [run_lengths_target_inds(2:2:end), 0];
                        for i = 1:length(run_lengths)
                            mask(target_index: target_index + run_lengths(i) - 1) = label;
                            target_index = target_index + run_lengths(i) + target_index_increment(i);
                        end               
                    case {MaskTypeRegular1, MaskTypeRegular2, MaskTypeRegular3}                
                        target_index = 1;
                        label = encoded_mask(2);
                        run_length = bitshift(uint32(encoded_mask(3)), 16) + bitshift(uint32(encoded_mask(4)), 8) + uint32(encoded_mask(5));
                        source_index = 6;
                        mask(target_index:target_index + run_length- 1) = label;
                        target_index = target_index + run_length;
                        step = (nr_bytes+1);
                        entries = (length(encoded_mask) - 5) / step;                
                        indices = source_index:source_index + step*entries - 1;
                        values = encoded_mask(indices);
                        labels = values(1:step:end);
                        run_lengths = zeros(1, length(labels), 'uint32');
                        for b = 1:nr_bytes
                            shift = shifts(b);
                            run_lengths = run_lengths + bitshift(uint32(values(b+1:step:end)), shift);
                        end               
                        for i = 1:length(labels)
                            mask(target_index: target_index + run_lengths(i) - 1) = labels(i);
                            target_index = target_index + run_lengths(i);
                        end           
                end      
            end
        end
        
        function [nr_bytes, shifts] = get_nr_bytes(type)
            MaskTypeEmpty = 0;
            MaskTypeFilled = 1;
            MaskTypeBitmask1 = 2;
            MaskTypeBitmask2 = 3;
            MaskTypeBitmask3 = 4;
            MaskTypeByteArray = 5;
            MaskTypeRegular1 = 6;
            MaskTypeRegular2 = 7;
            MaskTypeRegular3 = 8;
        
            nr_bytes = 1;
            shifts = [0];
            if type == MaskTypeRegular2 || type == MaskTypeBitmask2
                nr_bytes = 2;
                shifts = [8, 0];
            elseif type == MaskTypeRegular3 || type == MaskTypeBitmask3
                nr_bytes = 3;
                shifts = [16, 8, 0];
            end
        end
        
        function output = base64decode(input)
            error(nargchk(1, 1, nargin));
            error(javachk('jvm'));
            if ischar(input), input = uint8(input); end    
            output = typecast(org.apache.commons.codec.binary.Base64.decodeBase64(input), 'uint8')';
        end
    end
end

