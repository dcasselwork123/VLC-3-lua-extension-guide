-- Ultra Simple Test Extension
function descriptor()
    return {
        title = "TEST WORKS",
        version = "1.0",
        author = "Test",
        shortdesc = "If you see this, extensions work"
    }
end

function activate()
    vlc.msg.info("Test extension loaded!")
end
