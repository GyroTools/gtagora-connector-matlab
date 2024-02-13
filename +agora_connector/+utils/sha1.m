function hash = sha1(path)
    import agora_connector.utils.sha
    hash = sha(path, 'SHA-1');    
end