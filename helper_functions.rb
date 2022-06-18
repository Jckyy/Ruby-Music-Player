# Detects if a 'mouse sensitive' area has been clicked on
def area_clicked(leftX, topY, rightX, bottomY)
    if ((mouse_x > leftX and mouse_x < rightX) and (mouse_y < bottomY and mouse_y > topY))
        return true
    end
    return false
end    

# Convert track.duration to mm:ss
def convert_sec_to_time(length)
    minutes = length / 60
    seconds = (length % 60)
    if (seconds < 10)
        seconds = "0" + (seconds.to_i).to_s()
    else
        seconds = (seconds.to_i).to_s()
    end
    duration = "#{minutes.to_i}:#{seconds}"
    return duration
end

# Convert Gosu.milliseconds to mm:ss
def convert_milliseconds_to_time(milliseconds)
    seconds = milliseconds / 1000
    time = convert_sec_to_time(seconds)
    return time
end