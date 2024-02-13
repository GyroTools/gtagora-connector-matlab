function hash = sha(path, method)
    hash = [];
    try
        engine = java.security.MessageDigest.getInstance(method);    
    catch ME  % Handle errors during initializing the engine:        
        return;
    end
    [fid, Msg] = fopen(path, 'r');        % Open the file
    if fid < 0
        return;
    end

    % Read file in chunks to save memory and Java heap space:
    Chunk = 1e6;          % Fastest for 1e6 on Win7/64, HDD
    Count = Chunk;        % Dummy value to satisfy WHILE condition
    while Count == Chunk
        [Data, Count] = fread(fid, Chunk, '*uint8');
        if Count ~= 0      % Avoid error for empty file
            engine.update(Data);
        end
    end
    fclose(fid);
    hash = typecast(engine.digest, 'uint8');   
    hash = sprintf('%.2x', double(hash));
end