# Draw a coloured background using TOP_COLOR and BOTTOM_COLOR
def draw_background
    draw_quad(0,0, TOP_COLOR, 0, WINDOW_HEIGHT, BOTTOM_COLOR, WINDOW_WIDTH, 0, TOP_COLOR, WINDOW_WIDTH, WINDOW_HEIGHT, BOTTOM_COLOR, z = ZOrder::BACKGROUND)
end

# Draw the bar at the bottom
def draw_playback_footer() 
    # Footer background
    draw_rect(0, WINDOW_HEIGHT - 80 + @now_playing_font.height, WINDOW_WIDTH, WINDOW_HEIGHT, UI_BACKGROUND, ZOrder::UI, mode = :default)
    # Playback buttons
    draw_playback_buttons()
    # Now playing text
    if @currently_playing != nil
        draw_current_playing(@currently_playing, @current_album)
    else
        @now_playing_font.draw("Stopped",15, WINDOW_HEIGHT - @now_playing_font.height * 2, ZOrder::UI,1.0,1.0,UI_FONT_COLOUR)
    end
end

# Draw playblack control buttons
def draw_playback_buttons()
    # 0.04 scale is 20px
    i = 0
    top = WINDOW_HEIGHT - @now_playing_font.height * 2
    bottom = WINDOW_HEIGHT - @now_playing_font.height * 2 + 20
    # Stop Button
    left = WINDOW_WIDTH - 30 - (30 * i)
    right = WINDOW_WIDTH - 30 + 20 - (30 * i)
    dimensions = Dimensions.new(left,top,right,bottom)
    icon = Gosu::Image.new("icons/stop.png")
    @stop_button = Button.new(icon, dimensions)
    @stop_button.image.draw(@stop_button.dimensions.left, @stop_button.dimensions.top, ZOrder::UI, 0.04,0.04)
    i+=1
    
    # Next Button
    left = WINDOW_WIDTH - 30 - (30 * i)
    right = WINDOW_WIDTH - 30 + 20 - (30 * i)
    dimensions = Dimensions.new(left,top,right,bottom)
    icon = Gosu::Image.new("icons/next.png")
    @next_button = Button.new(icon, dimensions)
    @next_button.image.draw(@next_button.dimensions.left, @next_button.dimensions.top, ZOrder::UI, 0.04,0.04)
    i+=1
    
    # Pause Button
    left = WINDOW_WIDTH - 30 - (30 * i)
    right = WINDOW_WIDTH - 30 + 20 - (30 * i)
    dimensions = Dimensions.new(left,top,right,bottom)
    icon = Gosu::Image.new("icons/pause.png")
    @pause_button = Button.new(icon, dimensions)
    @pause_button.image.draw(@pause_button.dimensions.left, @pause_button.dimensions.top, ZOrder::UI, 0.04,0.04)
    i+=1
    
    # Play Button
    left = WINDOW_WIDTH - 30 - (30 * i)
    right = WINDOW_WIDTH - 30 + 20 - (30 * i)
    dimensions = Dimensions.new(left,top,right,bottom)
    icon = Gosu::Image.new("icons/play.png")
    @play_button = Button.new(icon, dimensions)
    @play_button.image.draw(@play_button.dimensions.left, @play_button.dimensions.top, ZOrder::UI, 0.04,0.04)

    @buttons_array = [@stop_button, @next_button, @pause_button, @play_button]
end

# Draws multiple pages dependent on how many tracks loaded.
def draw_page_header() 
    @page_dimensions = []
    # Header Background
    draw_rect(0, 0, PLAYER_WIDTH, 40, UI_BACKGROUND, ZOrder::PLAYER, mode = :default)
    # Draw the pages: top, bottom, right are the same for all buttons
    top = 35
    bottom = 5
    right = 40
    i = 0
    while i < @pages_required
        left = 0 + (i * 50)
        draw_rect(left,top,right,bottom, BUTTON_COLOUR, ZOrder::UI, mode = :default)
        @page_dimensions << Dimensions.new(left,0,left+right,40) # Full header width unlike the draw_rect
        if (@current_page == i + 1)
            @button_font.draw(i+1, left+10,0,ZOrder::UI,1.0,1.0,SELECTED_UI_FONT_COLOUR)
        else
            @button_font.draw(i+1, left+10,0,ZOrder::UI,1.0,1.0,UI_FONT_COLOUR)
        end
        i+=1
    end
    
    # Header Search Button
    left = PLAYER_WIDTH - 40
    draw_rect(left,top,right,bottom, BUTTON_COLOUR, ZOrder::UI, mode = :default)
    right = left + 40
    top = 0
    bottom = top + 40
    icon = Gosu::Image.new("icons/search.png")
    dimensions = Dimensions.new(left,top,right,bottom)
    @search_button = Button.new(icon, dimensions)
    @search_button.image.draw(@search_button.dimensions.left, @search_button.dimensions.top, ZOrder::UI, 0.08,0.08)
end

def draw_sidebar()
    draw_rect(PLAYER_WIDTH,0,WINDOW_WIDTH,WINDOW_HEIGHT, SIDEBAR_COLOUR, ZOrder::BACKGROUND, mode = :default)
    @now_playing_font.draw("Playback Queue", PLAYER_WIDTH + 30, 10, ZOrder::UI, 1.0, 1.0, UI_FONT_COLOUR)
    draw_rect(PLAYER_WIDTH, 40 - 1, WINDOW_WIDTH - PLAYER_WIDTH, 2, SPLITTER_COLOUR, ZOrder::UI, mode = :default)
    # Draw queue
    if @playback_queue.length == 0
        return
    else
        i = 0
        track_y_pos = 60
        while (i < @playback_queue.length)
            @track_font.draw(@music_library[@playback_queue[i][0]].tracks[@playback_queue[i][1]].title, PLAYER_WIDTH + 10, track_y_pos, ZOrder::UI, 1.0, 1.0, FONT_COLOUR)
            i+=1
            track_y_pos += @track_font.height + 2
        end
    end
end