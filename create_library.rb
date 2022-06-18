require 'wahwah'

# tag = WahWah.open("./sounds/Caravan Palace/1 - Caravan Palace - Dragons.mp3")

# tag.title       # => "song title" 
# tag.artist      # => "artist name"
# tag.album       # => "album name"
# tag.albumartist # => "albumartist name"
# tag.track       # => 1
# tag.track_total # => 10
# tag.genre       # => "Rock"
# tag.year        # => "1984"
# tag.duration    # => 256.1 (in seconds) 
# tag.bitrate     # => 192 (in kbps) 
# tag.sample_rate # => 44100 (in Hz)
# tag.images      # => [{ :type => :cover_front, :mime_type => 'image/jpeg', :data => 'image data binary string' }]

# Get albums from /sounds directory
def create_library
    puts("Looking for music in /sounds")
    album_library = read_albums()
    puts("Sucessfully loaded #{album_library.length} album(s) from the /sounds folder")
    return album_library
end

def read_albums
    album_library = []
    # Set album folder and clean
    albums_arr = Dir.entries("./sounds")
    albums_arr.delete(".")
    albums_arr.delete("..")
    # Get tracks in each album
    for album in albums_arr
        tracks_arr = read_tracks(album)
        new_album = create_album_class(album, tracks_arr)
        album_library << new_album

    end
    return album_library
end

def read_tracks(album)
    track_directory = Dir.entries("./sounds/#{album}")
    track_directory.delete(".")
    track_directory.delete("..")
    tracks_arr = []
    for item in track_directory
        # remove jpg files
        if (!item.include?(".jpg"))
            # get metadata
            track = WahWah.open("./sounds/#{album}/#{item}")
            tracks_arr << track 
        end
    end
    bubble_sort(tracks_arr)
    return tracks_arr
end

def create_album_class(album, tracks_arr)
    album_title = tracks_arr[0].album
    if (tracks_arr[0].albumartist != nil)
        album_artist = tracks_arr[0].albumartist
    else
        album_artist = tracks_arr[0].artist
    end
    album_year = tracks_arr[0].year
    track_total = tracks_arr.length
    album_location = "./sounds/#{album}/"
    artwork = Artwork.new(album_location + "folder.jpg")
    new_album =  Album.new(album_title,album_artist, album_year, track_total, tracks_arr, album_location, artwork)
    return new_album
end

def bubble_sort(list)
    return list if list.size <= 1 # already sorted
    swapped = true
    while swapped do
      swapped = false
      0.upto(list.size-2) do |i|
        if list[i].track > list[i+1].track
          list[i], list[i+1] = list[i+1], list[i] # swap values
          swapped = true
        end
      end    
    end
  
    list
  end