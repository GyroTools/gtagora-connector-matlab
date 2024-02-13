function hash = sha256(path)
    import agora_connector.utils.sha
    hash = sha(path, 'SHA-256');    
end