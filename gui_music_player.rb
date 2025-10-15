  require './input_functions'
  require 'rubygems'
  require 'gosu'

  TOP_COLOR = Gosu::Color.new(0xFF1EB1FA)
  BOTTOM_COLOR = Gosu::Color.new(0xFF1D4DB5)


  module Genre
    POP, CLASSIC, JAZZ, ROCK, VARIOUS = *1..5
  end

  $genre_names = ['Null', 'Pop', 'Classic', 'Jazz', 'Rock', 'Various']


  def read_track(music_file, id, artist = nil, genre = nil)
      track_id = id
      name = music_file.gets.chomp()
      location = music_file.gets.chomp()
      duration = music_file.gets.chomp()
      track = Track.new(track_id, name, location, duration)
      return track	
  end

  def read_tracks(music_file, count, artist = nil, genre = nil)
    tracks = Array.new()
    index = 0
    while index < count.to_i
        track = read_track(music_file, index+1)
        tracks << track
        index += 1
      end

    return tracks
  end

  def print_track(track)
    puts(track.name)
    puts(track.location)
    puts(track.duration)
  end

  def print_tracks(tracks)
    index = 0
    while index < tracks.length
      puts('Track ID: ' + ((index+1).to_s))
      print_track(tracks[index])
      index = index + 1
    end
  end

  def read_album(music_file, id)
    album_id = id
    album_artist = music_file.gets.chomp
    album_title = music_file.gets.chomp
    album_image = music_file.gets.chomp
    album_genre = music_file.gets.chomp
    tracks_amount = music_file.gets.chomp
    tracks = read_tracks(music_file, tracks_amount, album_artist, album_genre)
    album = Album.new(album_id, album_artist, album_title, album_image, album_genre, tracks_amount, tracks)
    return album
  end

  def read_albums(music_file)
    count = music_file.gets().to_i()
    index = 0
    albums = Array.new()
    while index < count
      album = read_album(music_file, index + 1)
      albums << album
      index = index + 1
    end
    return albums
  end

  def print_album(album)
    puts('Album ID: ' + album.id.to_s)
    puts('Artist: ' + album.artist)
    puts('Title: ' + album.title)
    puts('Image: ' + album.image)
    puts('Genre: ' + $genre_names[album.genre.to_i])
    puts('Tracks amount: ' + album.tracks_amount.to_s)
    print_tracks(album.tracks)
  end

  def print_albums(albums)
    index = 0
    while index < albums.length
      print_album(albums[index])
      index = index + 1
    end
  end


  module ZOrder
    BACKGROUND, PLAYER, UI = *0..2
  end

  class ArtWork
    attr_accessor :bmp

    def initialize (file)
        @bmp = Gosu::Image.new(file)
    end
  end

  # Put your record definitions here
  class Album
    attr_accessor :id, :title, :artist, :image, :genre, :tracks, :tracks_amount

    def initialize (id, artist, title, image, genre, tracks_amount, tracks)
      @id = id
      @artist = artist
      @title = title
      @image = image
      @genre = genre
      @tracks_amount = tracks_amount
      @tracks = tracks
    end
  end

  class Track
    attr_accessor :track_id, :name, :location, :duration, :artist, :genre

    def initialize (track_id, name, location, duration, artist = nil, genre = nil)
      @track_id = track_id
      @name = name
      @location = location
      @duration = duration
      @artist = nil
      @genre = nil
    end
  end

  WIN_WIDTH = 1280
  WIN_HEIGHT = 720

  class MusicPlayerMain < Gosu::Window

    def initialize
      @title_input_mode = false
      @new_album_title = ""
      @pause_button_x = WIN_WIDTH - 400
      @pause_button_y = 600
      @pause_button_width = 50
      @pause_button_height = 50
      @is_paused = false
      @pause_img = Gosu::Image.new("media/pause.png")
      @play_img = Gosu::Image.new("media/play.png")
      @upload_image_mode = false       # checks if user is currently typing a file name
      @uploaded_image_name = ""        # Store the typed filename
      @new_album_image = "media/default.png" # Default image for new albums
      @selected_tracks_for_new_album = [] # For storing selected tracks for new playlist
      @playlist_page = 0 # Current page on playlist screen
      @tracks_per_page = 8 # Show 8 tracks per page
      @current_page_state = :albums #tracks which page we are on
      @song = nil #this is for the song that is playing
      @selected_track = nil #this is to know which album and track is selected
      @selected_album = nil 
      @arrow_x_left = 50 #this is to position the arrows
      @arrow_x_right = 230
      @arrow_y = 0
      @current_page = 0 #this is to keep track of which page we are on
      @albums_per_page = 4 #number of albums per page
      @spacing_x = 300 #spacing between albums
      @spacing_y = 280
      super WIN_WIDTH, WIN_HEIGHT
      self.caption = "Music Player"
      @background = Gosu::Color::WHITE 
      # Reads in an array of albums from a file and then prints all the albums in the
      # array to the terminal
      music_file = File.new("albums.txt", "r")
      @albums = read_albums(music_file)
      @artworks = @albums.map do |album|
        begin
          ArtWork.new(album.image)
        rescue
          ArtWork.new("media/default.png") # fallback image
        end
      end
      print_albums(@albums)
      @font = Gosu::Font.new(20)
    end

    # Put in your code here to load albums and tracks
    
    # Draws the artwork on the screen for all the albums

    def draw_albums
      start_index = @current_page * @albums_per_page
      end_index = start_index + @albums_per_page - 1

      albums_to_display = @albums[start_index..end_index] || []
      artworks_to_display = @artworks[start_index..end_index] || []

      # Adjust scale and spacing
      image_width = 150
      image_height = 150
      margin_left = 50
      margin_top = 50
      total_cols = 2

      @album_positions = Array.new()

      albums_to_display.each_with_index do |album, i|
        col = i % total_cols
        row = i / total_cols
        x = margin_left + col * @spacing_x
        y = margin_top + row * @spacing_y

        artworks_to_display[i].bmp.draw(x, y, ZOrder::PLAYER, 0.8, 0.8)
        @font.draw_text("#{album.title}", x, y + image_height + 70, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
        @font.draw_text("#{album.artist}", x, y +image_height + 90, ZOrder::UI, 0.9, 0.9, Gosu::Color::BLACK)
        padding = 80
        @album_positions << {album: album, x1: x - padding, y1: y - padding, x2: x + image_width + padding, y2: y + image_height + padding}
      end

      # Store bottom Y position for arrows
      @arrow_y = 100 + 2 * @spacing_y
    end


    # Detects if a 'mouse sensitive' area has been clicked on
    # i.e either an album or a track. returns true or false

    def area_clicked(leftX, topY, rightX, bottomY)
      mouse_x > leftX && mouse_x < rightX && mouse_y > topY && mouse_y < bottomY
    end


    # Takes a String title and an Integer ypos
    # You may want to use the following:
    def display_track(title, ypos)
      @track_font.draw(title, TrackLeftX, ypos, ZOrder::PLAYER, 1.0, 1.0, Gosu::Color::BLACK)
    end


    # Takes a track index and an Album and plays the Track from the Album

    def playTrack(track, album)
      @song = Gosu::Song.new(album.tracks[track].location)
      @song.play(false)
    end

  # Draw a coloured background using TOP_COLOR and BOTTOM_COLOR

    def draw_background
      draw_quad(0, 0, Gosu::Color::GREEN, WIN_WIDTH, 0, Gosu::Color::GREEN, WIN_WIDTH, WIN_HEIGHT, Gosu::Color.new(0xFF006400), 0, WIN_HEIGHT, Gosu::Color.new(0xFF006400), z = ZOrder::BACKGROUND, mode = :default)
    end

    def draw_arrows
      max_page = (@albums.length - 1) / @albums_per_page

      # Change colour based on whether navigation is possible
      left_color = @current_page > 0 ? Gosu::Color::BLACK : Gosu::Color::GRAY
      right_color = @current_page < max_page ? Gosu::Color::BLACK : Gosu::Color::GRAY

      @font.draw_text("< Prev", @arrow_x_left, @arrow_y, ZOrder::UI, 1.2, 1.2, left_color)
      @font.draw_text("Next >", @arrow_x_right + 80 , @arrow_y, ZOrder::UI, 1.2, 1.2, right_color)

      page_text = "Page #{@current_page + 1} / #{max_page + 1}"
      middle_x = (@arrow_x_left + @arrow_x_right) / 2 + 30
      @font.draw_text(page_text, middle_x, @arrow_y + 2, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def draw_selected_album_tracks
      return unless @selected_album
      x = @spacing_x * 2
      y = 50
      @font.draw_text("Tracks for: #{@selected_album.title}", x, y, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      y += 30
      @track_positions = []
      @selected_album.tracks.each_with_index do |track, index|
        color = (@selected_track == track) ? Gosu::Color::RED : Gosu::Color::BLACK
        genre_name = track.genre || $genre_names[@selected_album.genre.to_i] rescue "Unknown"
        artist_name = track.artist || @selected_album.artist
        text = "#{track.name} (#{track.duration}) - #{genre_name} - #{artist_name}"
        @font.draw_text((index + 1).to_s + " " + text, x, y, ZOrder::UI, 0.9, 0.9, color)
        @track_positions << { track: track, x1: x, y1: y, x2: x + 400, y2: y + 25 }
        y += 25
      end
      if @selected_track
        @font.draw_text("Now Playing: #{@selected_track.name}", x, y + 30, ZOrder::UI, 1.2, 1.2, Gosu::Color::BLUE)
      end

    end

    def draw_create_album_button
      @create_album_x = WIN_WIDTH - 250
      @create_album_y = WIN_HEIGHT - 80
      @create_album_width = 200
      @create_album_height = 50

      Gosu.draw_rect(@create_album_x, @create_album_y, @create_album_width, @create_album_height, Gosu::Color::CYAN, ZOrder::UI)
      @font.draw_text("Create Album", @create_album_x + 20, @create_album_y + 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def create_album_button_clicked?
      area_clicked(@create_album_x, @create_album_y, @create_album_x + @create_album_width, @create_album_y + @create_album_height)
    end

    def draw_create_playlist_button
      @button_x = WIN_WIDTH - 250
      @button_y = 20
      @button_width = 200
      @button_height = 50

      Gosu.draw_rect(@button_x, @button_y, @button_width, @button_height, Gosu::Color::CYAN, ZOrder::UI)
      @font.draw_text("Create Playlist", @button_x + 20, @button_y + 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
    end

    def create_playlist_button_clicked?
      area_clicked(@button_x, @button_y, @button_x + @button_width, @button_y + @button_height)
    end

    def draw_upload_image_button
      @upload_x = WIN_WIDTH - 250
      @upload_y = 100
      @upload_width = 200
      @upload_height = 50

      Gosu.draw_rect(@upload_x, @upload_y, @upload_width, @upload_height, Gosu::Color::CYAN, ZOrder::UI)
      @font.draw_text("Upload Image", @upload_x + 20, @upload_y + 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

      if @upload_image_mode
        # Draw input box
        Gosu.draw_rect(@upload_x, @upload_y + 60, @upload_width, @upload_height, Gosu::Color::WHITE, ZOrder::UI)
        @font.draw_text(@uploaded_image_name, @upload_x + 10, @upload_y + 65, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      end
    end

    def upload_button_clicked?
      area_clicked(@upload_x, @upload_y, @upload_x + @upload_width, @upload_y + @upload_height)
    end

    def draw_title_input_button
      @title_x = WIN_WIDTH - 250
      @title_y = 300
      @title_width = 200
      @title_height = 50

      Gosu.draw_rect(@title_x, @title_y, @title_width, @title_height, Gosu::Color::CYAN, ZOrder::UI)
      @font.draw_text("Enter Title", @title_x + 20, @title_y + 15, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)

      if @title_input_mode
        Gosu.draw_rect(@title_x, @title_y + 60, @title_width, @title_height, Gosu::Color::WHITE, ZOrder::UI)
        @font.draw_text(@new_album_title, @title_x + 10, @title_y + 65, ZOrder::UI, 1.0, 1.0, Gosu::Color::BLACK)
      end
    end

    def title_button_clicked?
      area_clicked(@title_x, @title_y, @title_x + @title_width, @title_y + @title_height)
    end

    def draw_create_playlist_page
      x = 50
      y = 50
      @font.draw_text("Add Tracks to Playlist", x, y, ZOrder::UI, 1.5, 1.5, Gosu::Color::BLACK)
      y += 50
      
      # Flatten all tracks from all albums into one array
      all_tracks = @albums.flat_map { |album| album.tracks }

      # Determine the range of tracks to display on the current page
      start_index = @playlist_page * @tracks_per_page
      end_index = start_index + @tracks_per_page - 1
      tracks_to_display = all_tracks[start_index..end_index] || []

      @track_positions = []

      total_pages = (all_tracks.length.to_f / @tracks_per_page).ceil
      prev_color = @playlist_page > 0 ? Gosu::Color::BLACK : Gosu::Color::GRAY
      next_color = @playlist_page < total_pages - 1 ? Gosu::Color::BLACK : Gosu::Color::GRAY
      tracks_to_display.each_with_index do |track, i|
        album = @albums.find { |a| a.tracks.include?(track) }
        color = @selected_tracks_for_new_album.include?(track) ? Gosu::Color::RED : Gosu::Color::BLACK
        @font.draw_text("#{track.name} - #{album.artist}", x, y, ZOrder::UI, 1.0, 1.0, color)
        @track_positions << { track: track, x1: x, y1: y, x2: x + 400, y2: y + 25 }
        y += 30
      end

      # After drawing all tracks, y points to bottom of last track
      @pagination_y = y + 20
      @font.draw_text("< Prev", x, @pagination_y, ZOrder::UI, 1.0, 1.0, prev_color)
      @font.draw_text("Next >", x + 100, @pagination_y, ZOrder::UI, 1.0, 1.0, next_color)
      draw_create_album_button
      draw_upload_image_button
      draw_title_input_button
    end

    def draw_pause_button
      img = @is_paused ? @play_img : @pause_img
      img.draw(@pause_button_x, @pause_button_y, ZOrder::UI, 0.1, 0.1)
    end

    def update
    end

    def draw
        draw_background
        if @current_page_state == :albums
          draw_albums
          draw_arrows
          draw_selected_album_tracks
          draw_create_playlist_button
          draw_pause_button
        elsif @current_page_state == :create_playlist
          draw_create_playlist_page
        end
    end 

    def needs_cursor? 
      true
    end

    # If the button area (rectangle) has been clicked on change the background color
    # also store the mouse_x and mouse_y attributes that we 'inherit' from Gosu
    # you will learn about inheritance in the OOP unit - for now just accept that
    # these are available and filled with the latest x and y locations of the mouse click.

    def button_down(id)
      if @upload_image_mode || @title_input_mode
        if id == Gosu::KbReturn
          if @upload_image_mode
            # Press Enter: finalize image filename
            @new_album_image = "media/#{@uploaded_image_name}.png"
            @uploaded_image_name = ""
            @upload_image_mode = false
          elsif @title_input_mode
            @title_input_mode = false
          end
        elsif id == Gosu::KbBackspace
          if  @upload_image_mode
            @uploaded_image_name.chop! # remove last char
          elsif @title_input_mode
            @new_album_title.chop!
          end
        else
          char = Gosu.button_id_to_char(id)
          if char
            shift = Gosu.button_down?(Gosu::KbLeftShift) || Gosu.button_down?(Gosu::KbRightShift)
            char.upcase! if shift
            if @upload_image_mode
              @uploaded_image_name += char
            elsif @title_input_mode
              @new_album_title += char

            end
          end
        end
        return
      end
      if id == Gosu::MsLeft
        if @current_page_state == :albums
          if area_clicked(@pause_button_x, @pause_button_y, @pause_button_x + @pause_button_width * 1, @pause_button_y + @pause_button_height)
            if @song
              if @is_paused
                @song.play(false)
                @is_paused = false
              else
                @song.pause
                @is_paused = true
              end
            end
          end
          if create_playlist_button_clicked?
            @current_page_state = :create_playlist
            return
          end
          if area_clicked(@arrow_x_left, @arrow_y, @arrow_x_left + 80, @arrow_y + 40)
            @current_page -= 1 if @current_page > 0
          elsif area_clicked(@arrow_x_right + 80, @arrow_y, @arrow_x_right + 160, @arrow_y + 40)
            max_page = (@albums.length - 1) / @albums_per_page
            @current_page += 1 if @current_page < max_page
          else
            clicked_album = @album_positions.find { |pos| area_clicked(pos[:x1], pos[:y1], pos[:x2], pos[:y2]) }
            if clicked_album
              @selected_album = clicked_album[:album]
              @selected_track = nil
            elsif @selected_album && @track_positions
              clicked_track = @track_positions.find { |pos| area_clicked(pos[:x1], pos[:y1], pos[:x2], pos[:y2]) }
              if clicked_track
                @selected_track = clicked_track[:track]
                track = clicked_track[:track]
                @song = nil
                @is_paused = false
                @song.stop if @song && @song.playing?
                if track.location && !track.location.empty? && File.exist?(track.location)
                  begin
                    @song = Gosu::Song.new(@selected_track.location)
                    @song.play(false)
                    @is_paused = false 
                    @selected_track = track
                  rescue #adding this makes it so that it doesnt crash if the file is missing
                    @song = nil
                    @selected_track = nil 
                    puts "cannot play this track: #{track.location}"
                  end
                else 
                  @selected_track = nil
                  puts "Track location is invalid or file does not exist."
                end
              end
            end
          end
        elsif @current_page_state == :create_playlist
          # Pagination clicks
          all_tracks = @albums.flat_map { |album| album.tracks }
          total_pages = (all_tracks.length.to_f / @tracks_per_page).ceil

          # Check if user clicked pagination buttons
          all_tracks = @albums.flat_map { |album| album.tracks }
          start_index = @playlist_page * @tracks_per_page
          end_index = start_index + @tracks_per_page - 1
          tracks_to_display = all_tracks[start_index..end_index] || []
          
          if upload_button_clicked?
            @upload_image_mode = true
          end  

          if title_button_clicked?
            @title_input_mode = true
          end

          x = 50
          y = 50 + 50 + tracks_to_display.length * 30
          if area_clicked(x, @pagination_y, x + 60, @pagination_y + 25) && @playlist_page > 0
            @playlist_page -= 1
          elsif area_clicked(x + 100, y + 20, x + 180, y + 45) && @playlist_page < total_pages - 1
            @playlist_page += 1
          end

          # Check if user clicked a track to add (well implement actual adding later)
          clicked_track = @track_positions.find { |pos| area_clicked(pos[:x1], pos[:y1], pos[:x2], pos[:y2]) }
          if clicked_track
            track = clicked_track[:track]
            # toggle selection
            if @selected_tracks_for_new_album.include?(track)
              @selected_tracks_for_new_album.delete(track)
            else
                @selected_tracks_for_new_album << track
            end
          end
          if create_album_button_clicked?
            if @selected_tracks_for_new_album.any?
              title = @new_album_title.strip.empty? ? "New Album" : @new_album_title
              new_album = Album.new(@albums.length + 1, "Player", title, @new_album_image, Genre::VARIOUS, @selected_tracks_for_new_album.length, @selected_tracks_for_new_album.dup)
              title = ""
              @new_album_image = "media/default.png" # Reset to default for next album
              @albums << new_album
              @artworks << ArtWork.new(new_album.image)
              puts "New album created with #{@selected_tracks_for_new_album.length} tracks!"
              @selected_tracks_for_new_album.clear
              @current_page_state = :albums
            else 
              puts("No tracks selected for new album.")
            end
          end
        end
      end
    end
  end

  # Show is a method that loops through update and draw

  MusicPlayerMain.new.show if __FILE__ == $0
