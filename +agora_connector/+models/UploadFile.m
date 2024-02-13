classdef UploadFile
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        id = [];
        file = [];
        target = [];
        zip = false;
        size = [];
        size_uploaded = 0;
        nr_chunks = [];
        chunks_completed = [];
        identifier = [];
        uploaded = false;
        imported = false
    end

    methods        
    end
end