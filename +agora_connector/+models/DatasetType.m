classdef DatasetType
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Constant)                
        NONE = 0;
        PHILIPS_RAW = 100;
        PHILIPS_PARREC = 101;
        PHILIPS_SPECTRO = 102;
        
        BRUKER_RAW = 200;
        BRUKER_SUBJECT = 201;
        BRUKER_IMAGE = 202;
        DICOM = 300;
        SIEMENS_RAW = 400;
        ISMRMRD = 500;
        NIFTI1 = 600;
        NIFTI2 = 601;
        NIFTI_ANALYZE75 = 602;
        JMRUI_SPECTRO = 700;
        QUERY = 10000;
        OTHER = 100000;
    end        
end

