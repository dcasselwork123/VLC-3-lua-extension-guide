-- Minimal Test Extension for VLC
-- This is the absolute simplest extension possible

function descriptor()
    return {
        title = "Simple Test",
        version = "1.0",
        author = "Test",
        shortdesc = "Test extension",
        description = "If you see this in VLC, extensions are working!"
    }
end

function activate()
    vlc.msg.info("Test extension activated!")
end
