require 'rubygems'
require 'gosu'
require './create_library.rb'
require './draw_permanent_ui.rb'
require './helper_functions.rb'


TOP_COLOR = Gosu::Color.new(0xFF2f383e)
BOTTOM_COLOR = Gosu::Color.new(0xFF2f383e)
HIGHLIGHT_COLOR = Gosu::Color.new(0xFF434e54)
UI_BACKGROUND = Gosu::Color.new(0xFF404c51)
FONT_COLOUR = Gosu::Color.new(0xFFdcd8c4)
UI_FONT_COLOUR = Gosu::Color.new(0xFF7fbbb3)
SELECTED_UI_FONT_COLOUR = Gosu::Color.new(0xFFd699b6)
BUTTON_COLOUR = Gosu::Color.new(0xFFa7c080)
HIDDEN_BUTTON_COLOUR = Gosu::Color.new(0x00007987)
SPLITTER_COLOUR = Gosu::Color.new(0xFF4e5a5d)
SIDEBAR_COLOUR = Gosu::Color.new(0xFF374247)

module ZOrder
    BACKGROUND, PLAYER, UI = *0..2
end

class Artwork
	attr_accessor :img
	def initialize (file)
		@img = Gosu::Image.new(file)
	end
end

class Album
    attr_accessor :title, :artist, :tracks, :track_count, :artwork, :page, :year, :location, :start_y, :end_y, :search_result
    def initialize (title, artist, year, track_count, tracks, location, artwork)
        @title = title
        @artist = artist
        @tracks = tracks
        @artwork = artwork
        @page = nil
        @year = year
        @track_count = track_count
        @location = location
        @start_y = nil
        @end_y = nil
        @search_result = false
    end
end

class Dimensions
    attr_accessor :left, :top, :right, :bottom
    def initialize (left, top, right, bottom)
        @left = left
        @top = top
        @right = right
        @bottom = bottom
    end
end

class Button 
    attr_accessor :image, :dimensions
    def initialize (image, dimensions)
        @image = image
        @dimensions = dimensions
    end
end

WINDOW_WIDTH = 900
WINDOW_HEIGHT = 850
PLAYER_WIDTH = 700
TrackLeftX = 190
PAGE_HEADER = 40
FIRST_ALBUM_START = 45
PAGE_CUTOFF = WINDOW_HEIGHT - PAGE_HEADER - 100    # 80 is the footer

class MusicPlayerMain < Gosu::Window
	def initialize
	    super WINDOW_WIDTH, WINDOW_HEIGHT
	    self.caption = "Music Player"
        @track_font = Gosu::Font.new(15)
        @album_font = Gosu::Font.new(18)
        @info_font = Gosu::Font.new(15)
        @now_playing_font = Gosu::Font.new(20)
        @button_font = Gosu::Font.new(40)
		# Reads in an array of albums from a file and then prints all the albums in the
		# array to the terminal
        @music_library = create_library()
        set_dimensions()
        set_pages()
        @currently_playing = nil
        @current_album = nil
        @current_page = 1
        @playback_queue = []
        self.text_input = Gosu::TextInput.new
        @search_result = []
	end

    # Create Start and End Y positions for the albums depending on tracks
    def set_dimensions
        i = 0
        min_album_height = 200
        # Used later for how many pages required
        @total_album_height = 0
        # Set Album Dimensions
        while (i < @music_library.length)
            # Create first album to have an end reference for the rest of the albums
            if (i == 0)
                album_start_y = FIRST_ALBUM_START
                # If the album has 6 or less tracks, we can just use the minimum height
                if (@music_library[i].track_count < 6)
                    album_end_y = album_start_y + min_album_height
                # If album needs more space, add track count * (track height + 1px vertical padding each side) + 20px from where the tracks start
                else
                    album_end_y = album_start_y + (@music_library[i].track_count * (@track_font.height + 2) + 20)
                end
                @music_library[i].start_y = album_start_y
                @music_library[i].end_y = album_end_y
                @total_album_height += min_album_height
            else
                # Start next album 10px under the previous album
                album_start_y = @music_library[i-1].end_y + 5
                if (@music_library[i].track_count < 6)
                    album_end_y = album_start_y + min_album_height
                else
                    album_end_y = album_start_y + (@music_library[i].track_count * (@track_font.height + 2) + 20)
                end
                @music_library[i].start_y = album_start_y
                @music_library[i].end_y = album_end_y
                @total_album_height += album_end_y - album_start_y
            end
            i+=1
        end
        @pages_required = (@total_album_height / PAGE_CUTOFF.to_f).ceil
    end

    def set_pages()
        i = 0
        page_2_count = 0
        page_3_count = 0
        page_4_count = 0
        while (i < @music_library.length)
            album_height = @music_library[i].end_y - @music_library[i].start_y
            # Page 1 Allocation
            if @music_library[i].end_y < PAGE_CUTOFF
                @music_library[i].page = 1
            end
            # Page 2 Allocation
            if @music_library[i].end_y > PAGE_CUTOFF && @music_library[i].end_y <= PAGE_CUTOFF * 2
                calculate_page(i, 2, page_2_count, album_height)
                page_2_count += 1
            end
            # Page 3 Allocation
            if @music_library[i].end_y > PAGE_CUTOFF * 2 && @music_library[i].end_y <= PAGE_CUTOFF * 3
                calculate_page(i, 3, page_3_count, album_height)
                page_3_count += 1
            end
            # Page 4 Allocation
            if @music_library[i].end_y > PAGE_CUTOFF * 3 && @music_library[i].end_y <= PAGE_CUTOFF * 4
                calculate_page(i, 4, page_4_count, album_height)
                page_4_count += 1
            end
            i += 1
        end
    end

    def calculate_page(i, page, page_count, album_height)
        if (page_count == 0)
            @music_library[i].start_y = FIRST_ALBUM_START 
        else
            @music_library[i].start_y = @music_library[i-1].end_y + 5
        end
        @music_library[i].end_y = @music_library[i].start_y + album_height
        @music_library[i].page = page
    end

    # Draws the artwork on the screen for all the albums for each page
    def draw_albums()
        for album in @music_library
            if (album.page == @current_page)
                draw_one_album(album)
            end
        end
    end

    # Draws one album and the tracks next to it
    def draw_one_album(album)
        # Album Text
        @album_font.draw("#{album.title} by #{album.artist}", 15, album.start_y, ZOrder::UI, 1.0, 1.0, FONT_COLOUR)
        draw_rect(@album_font.text_width("#{album.title} by #{album.artist}") + 20, album.start_y + (@album_font.height / 2) - 1, PLAYER_WIDTH - (@album_font.text_width("#{album.title} by #{album.artist}") + 20), 2, SPLITTER_COLOUR, ZOrder::UI, mode = :default)
        image_start = album.start_y + 20
        # Album artwork
        album.artwork.img.draw(15, image_start, ZOrder::UI,0.75,0.75)
        # Album Information
        metadata_start = image_start + 150 + 5
        @track_font.draw("Year: #{album.year}\nTracks: #{album.track_count}\n", 15, metadata_start, ZOrder::UI, 1.0, 1.0, FONT_COLOUR)
        # Album tracks
        track_i_pos = 0
        for track in album.tracks
            display_track("#{track.track} #{track.title}", image_start + track_i_pos, track.duration)
            track_i_pos += @track_font.height + 2
        end
    end

    # Draw indicator of the current playing song
	def draw_current_playing(index, album)
        if @song.paused?
            @now_playing_font.draw("Paused: #{@music_library[album].tracks[index].title}",15, WINDOW_HEIGHT - @now_playing_font.height * 2, ZOrder::UI,1.0,1.0,FONT_COLOUR)
        else
            # Draw playing indicator only if you're on the page
            tracks_start = (@music_library[@current_album].start_y + 20 - 1) + (@currently_playing * (@track_font.height + 2))
            if @current_page == @music_library[@current_album].page
                draw_rect(TrackLeftX - 15, tracks_start, 8, @track_font.height + 1, BUTTON_COLOUR, z = ZOrder::PLAYER)
            else
                draw_rect(TrackLeftX - 15, tracks_start, 8, @track_font.height + 1, HIDDEN_BUTTON_COLOUR, z = ZOrder::PLAYER)
            end

            # Draw now playing text in footer
            @now_playing_font.draw("Now playing: #{@music_library[album].tracks[index].title}",15, WINDOW_HEIGHT - @now_playing_font.height * 2, ZOrder::UI,1.0,1.0,UI_FONT_COLOUR)
            # Draw current playing track progress
            track_total_duration = convert_sec_to_time(@music_library[album].tracks[index].duration)
            current_track_duration_milliseconds = Gosu.milliseconds - @current_track_start_time
            current_track_playing_time = convert_milliseconds_to_time(current_track_duration_milliseconds)
            duration_string = "#{current_track_playing_time}/#{track_total_duration}"
            start_left = WINDOW_WIDTH - 50 - (30 * 3) - @now_playing_font.text_width(duration_string)
            @now_playing_font.draw(duration_string ,start_left, WINDOW_HEIGHT - @now_playing_font.height * 2, ZOrder::UI,1.0,1.0,UI_FONT_COLOUR)
        end
	end


    
    # Displays the text of the tracks
    def display_track(title, ypos, length)
        @track_font.draw(title, TrackLeftX, ypos, ZOrder::UI, 1.0, 1.0, FONT_COLOUR)
        duration = convert_sec_to_time(length)
        @track_font.draw(duration, PLAYER_WIDTH - @track_font.text_width(duration) - 5, ypos, ZOrder::UI, 1.0, 1.0, FONT_COLOUR)
    end



    # Takes a track index and an Album and plays the Track from the Album
    def play_track()
        @current_page = @music_library[@current_album].page
        @current_track_start_time = Gosu.milliseconds
        folder_location = @music_library[@current_album].location
        track = @music_library[@current_album].tracks[@currently_playing]

        song_file_name = "#{track.track} - #{@music_library[@current_album].artist} - #{track.title}.mp3"
        if song_file_name.include?("?")
            song_file_name.gsub!("?","_")
        end
        @song = Gosu::Song.new(folder_location + song_file_name)
        @song.play(false)
        puts("Now playing: " + track.title)
    end

    # Controls the playback buttons in footer
    def click_playback_button(option)
        case option
        # stop button
        when 0
            if @song == nil || @currently_playing == nil
                return
            else
                @song.stop
                @currently_playing = nil
                @current_album = nil
            end
        # next button
        when 1
            if @song == nil || @currently_playing == nil
                return
            # Play queue if it exists
            elsif (@playback_queue.length > 0)
                @current_album = @playback_queue[0][0]
                @currently_playing = @playback_queue[0][1]
                @playback_queue.shift
                play_track()
            # Play next song in album
            elsif (@currently_playing + 1 < @music_library[@current_album].tracks.length)
			    @currently_playing = @currently_playing + 1 
			    play_track()
            # Else play next album
            else
                if (@current_album < @music_library.length - 1)
                    @currently_playing = 0
                    @current_album += 1
                    play_track()
                else
                    @current_album = 0
                    @currently_playing = 0
                    @current_page = 1
                    play_track()
                end
            end
        # pause button
        when 2
            if @song == nil || @currently_playing == nil
                return
            elsif (@song.playing?)
                @song.pause
            end
        #play button
        when 3
            if @song == nil || @currently_playing == nil
                if @playback_queue.length > 0
                    @current_album = @playback_queue[0][0]
                    @currently_playing = @playback_queue[0][1]
                    @playback_queue.shift
                else
                    @current_album = 0
                    @currently_playing = 0
                end
                play_track()
            elsif (@song.paused?)
                @song.play
            end
        end
    end

    # Draw search page elements
    def draw_search_page() 
        # @now_playing_font.draw("Search", 15, FIRST_ALBUM_START + 10, ZOrder::UI, 1.0, 1.0, UI_FONT_COLOUR)
        if (self.text_input.text.length > 0)
            draw_rect(PLAYER_WIDTH - 70 - @track_font.text_width(self.text_input.text) - 5, 10, @track_font.text_width(self.text_input.text) + 10, @track_font.height + 5, TOP_COLOR, ZOrder::UI, mode = :default)
        end
        
        # Search text draw
        @track_font.draw(self.text_input.text,PLAYER_WIDTH - 70 - @track_font.text_width(self.text_input.text),20 - @track_font.height / 2, ZOrder::UI, 1,1, UI_FONT_COLOUR)
        # puts(self.text_input.text)
    end

    def show_search()
        # Album Search
        for album in @music_library
            # input_length = self.text_input.text.length
            if ((album.title.upcase.include?(self.text_input.text.upcase) || album.artist.upcase.include?(self.text_input.text.upcase)) && self.text_input.text.length > 0)
                album.search_result = true
                draw_one_album(album)
                break
            end
            # for track in album.tracks
            #     if (track.title.upcase.include?(self.text_input.text.upcase) && self.text_input.text.length > 0)
            #         album.search_result = true
            #         draw_one_album(album)
            #         # puts(album.search_result)
            #         break
            #     end 
            # end
            album.search_result = false
        end

        # # Track Search
        # for album in @music_library
        # end
    end

	def update
        if @song == nil || @currently_playing == nil 
            return
        elsif (!@song.playing?)
            if (@song.paused?)
                return
            # Play next song in queue if it exists
            elsif (@playback_queue.length > 0)
                @current_album = @playback_queue[0][0]
                @currently_playing = @playback_queue[0][1]
                @playback_queue.shift
            # Play next song in album, or next album
            elsif (@currently_playing + 1 < @music_library[@current_album].tracks.length)
			    # if @current
                @currently_playing = @currently_playing + 1 
			    play_track()
            end
		end
	end

    # Draws the album images and the track list for the selected album
	def draw
        # @track_font.draw(mouse_x,10, 250,ZOrder::UI, 1,1,FONT_COLOUR)
        # @track_font.draw(mouse_y,10, 265,ZOrder::UI, 1,1,FONT_COLOUR)
		draw_background()
        draw_albums()
        draw_page_header()
        draw_playback_footer()
        # Playback queue sidebar
        draw_sidebar()
        hover()
        # search page
        if @current_page == 0
            draw_search_page()
            show_search()
        end
	end

 	def needs_cursor?; true; end

    # Highlight track on hover
    def hover()
        for album in @music_library
            track_i_pos = 0
            for track in album.tracks
                image_start = album.start_y + 20
                if (area_clicked(TrackLeftX, image_start + track_i_pos - 1, PLAYER_WIDTH, image_start + track_i_pos + @track_font.height + 1) && (album.page == @current_page || album.search_result))
                    draw_rect(TrackLeftX - 4, image_start + track_i_pos - 1, PLAYER_WIDTH - TrackLeftX + 4, @track_font.height + 1, HIGHLIGHT_COLOR, ZOrder::PLAYER)
                    break
                end
                track_i_pos += @track_font.height + 2
            end
        end
    end

	def button_down(id)
		case id
	    when Gosu::MsLeft
            # Click on song
            album_i = 0
            for album in @music_library
                track_i_pos = 0
                track_i = 0
                for track in album.tracks
                    track_start = album.start_y + 20
                    if (area_clicked(TrackLeftX, track_start + track_i_pos - 1, PLAYER_WIDTH, track_start + track_i_pos + @track_font.height + 1) && (album.page == @current_page || album.search_result))
                        # reset search result
                        album.search_result = false

                        # Set the currently playing
                        @current_album = album_i
                        @currently_playing = track_i
                        play_track()
                        break
                    end
                    track_i += 1
                    track_i_pos += @track_font.height + 2
                end
                album_i += 1
            end
  
            # Playback buttons
            i = 0
            for button in @buttons_array
                if (area_clicked(button.dimensions.left,button.dimensions.top,button.dimensions.right,button.dimensions.bottom))
                    click_playback_button(i)
                end
                i += 1
            end
            
            # Change page click check
            i = 0
            for page in @page_dimensions
                if (area_clicked(page.left, page.top, page.right, page.bottom))
                    @current_page = i + 1
                end
                i+=1
            end

            # Search button
            if (area_clicked(@search_button.dimensions.left, @search_button.dimensions.top, @search_button.dimensions.right, @search_button.dimensions.bottom))
                @current_page = 0
                self.text_input.text = ""
            end

        when Gosu::MsRight
            # Right click on song adds to queue
            album_i = 0
            for album in @music_library
                track_i_pos = 0
                track_i = 0
                for track in album.tracks
                    track_start = album.start_y + 20    # Text starts same place as image
                    if (area_clicked(TrackLeftX, track_start + track_i_pos, PLAYER_WIDTH, track_start + track_i_pos + @track_font.height) && album.page == @current_page)
                        add_to_queue = [album_i, track_i]
                        @playback_queue << add_to_queue
                        puts("Added #{@music_library[album_i].tracks[track_i].title} to queue")
                        break
                    end
                    track_i += 1
                    track_i_pos += @track_font.height + 2
                end
                album_i += 1
            end
        end
	end


end

# Show is a method that loops through update and draw   
MusicPlayerMain.new.show if __FILE__ == $0