require 'pry'
require 'Geocoder'
require 'RestClient'
require 'colorize'
require 'colorized_string'
require 'json'
require 'tty-prompt'

class String
    def titleize
      self.split(" ").map{|word| word.capitalize}.join(" ")
    end
end

def welcome
    puts "Welcome to ".bold + "TV Guide".bold.colorize(:cyan) + "!".bold.colorize(:light_cyan)
    title_search
end

def title_search #get movie title to search
    puts "Reminder: Not all movies or shows are available for search".colorize(:red)
    prompt = TTY::Prompt.new
    choice = prompt.select("Are you searching for a Movie or Show?", %w(Movie Show Exit))
    if choice == "Movie"
        puts "Enter movie title".bold.colorize(:light_blue)
        origin_title = gets.chomp
        movie_search_query(origin_title)
    elsif choice == "Show"
        puts "Enter show name".bold.colorize(:light_blue)
        origin_title = gets.chomp
        show_search_query(origin_title)
    else
        puts "Thank you, come again!".bold
    end
end

def movie_search_query(origin_title) #search movie title, returns api search result body
    title = origin_title.gsub(/\s+/, "")
    search_result = RestClient.get("http://api-public.guidebox.com/v2/search?type=movie&field=title&query=#{title}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    resp_hash = JSON.parse(search_result.body)
    select_movie(resp_hash)
end

def select_movie(raw_result_hash) #takes search result body and allows user to choose the correct movie they are searching
    movie_name_year = raw_result_hash["results"].map{|movie| "#{movie["title"]}, #{movie["release_year"]}"}
    prompt = TTY::Prompt.new
    choice = (prompt.select("Which title?".colorize(:red), movie_name_year))
    get_movie_id(choice)
end

def get_movie_id(choice) #searches movie choice and returns correct movie ID
    list_choice = choice.gsub(/\s+/, "").sub(/,\d+/, "")
    choice_search = RestClient.get("http://api-public.guidebox.com/v2/search?type=movie&field=title&query=#{list_choice}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    choice_hash = JSON.parse(choice_search.body)
    id = choice_hash["results"].first["id"]
    get_movie_details(id)
end

def get_movie_details(id) #Uses movie ID to search API and return all details for movie
    movie_detail_hash = RestClient.get("http://api-public.guidebox.com/v2/movies/#{id}?api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    resp_hash = JSON.parse(movie_detail_hash.body)
    movie_menu(resp_hash)
end

def stream_source(resp_hash) #uses movie details to extract the streaming services movie is available on
    services = resp_hash["subscription_web_sources"].map{|source| source["display_name"]}
    if services.empty?
        puts "This movie does not appear to be available on any streaming services.".bold.colorize(:red)
        sleep 2
        movie_menu(resp_hash)
    else
        puts "#{resp_hash["title"].titleize} is available on #{services.join(", ").colorize(:light_red)}."
        sleep 2
        movie_menu(resp_hash)
    end
end

def movie_starring_cast(resp_hash) #uses movie details to extract starring cast and character names
    if resp_hash["cast"].empty?
        puts "There is no cast record found for this movie.".bold.colorize(:red)
        sleep 2
        movie_menu(resp_hash)
    else
        puts resp_hash["cast"].first(3).map{|source| source["character_name"].length > 0 ? "#{source["name"].colorize(:light_red)}, starred as #{source["character_name"].colorize(:light_red)}" : "#{source["name"].colorize(:light_red)}"}
        sleep 2
        movie_menu(resp_hash)
    end
end

def duration(resp_hash) #uses movie details to extract duration of movie in minutes
    duration_minutes = resp_hash["duration"]/60
    puts "#{resp_hash["title"]} is #{duration_minutes.to_s.colorize(:red)} minute#{plural(duration_minutes)} long."
    sleep 2
    movie_menu(resp_hash)
end

def movie_menu(resp_hash)
    prompt = TTY::Prompt.new
    choice = prompt.select("What would you like to know about the movie?".colorize(:light_blue)) do |menu|
        menu.choice name: 'What streaming service is this movie on?', value: 1
        menu.choice name: 'Who stars in this movie?', value: 2
        menu.choice name: 'How long is this movie?', value: 3
        menu.choice name: 'Search again', value: 4
        menu.choice name: 'Exit', value: 5
    end
    if choice == 1
        stream_source(resp_hash)
    elsif choice == 2
        movie_starring_cast(resp_hash)
    elsif choice == 3
        duration(resp_hash)
    elsif choice == 4
        sleep 1
        title_search
    else
        puts "Thank you, come again!".bold
    end
end

def plural(param)
    if param > 1
        return "s"
    end
end

##########################################################SHOWS###################################################################

def show_search_query(origin_title) #search movie title, returns api search result body
    title = origin_title.gsub(/\s+/, "")
    search_result = RestClient.get("http://api-public.guidebox.com/v2/search?type=show&field=title&query=#{title}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    resp_hash = JSON.parse(search_result.body)
    select_show(resp_hash)
end

def select_show(raw_result_hash) #takes search result body and allows user to choose the correct movie they are searching
    show_name_year = raw_result_hash["results"].map{|show| "#{show["title"]}, #{show["first_aired"].gsub(/-\d+/, "")}"}
    prompt = TTY::Prompt.new
    choice = (prompt.select("Which title?".colorize(:light_red), show_name_year))
    get_show_id(choice)
end

def get_show_id(choice) #searches movie choice and returns correct movie ID
    list_choice = choice.gsub(/\s+/, "").sub(/,\d+/, "")
    choice_search = RestClient.get("http://api-public.guidebox.com/v2/search?type=show&field=title&query=#{list_choice}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    choice_hash = JSON.parse(choice_search.body)
    id = choice_hash["results"].first["id"]
    get_show_details(id)
end

def get_show_details(id) #Uses show ID to search API and return all details for show
    show_detail_hash = RestClient.get("http://api-public.guidebox.com/v2/shows/#{id}?api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
    resp_hash = JSON.parse(show_detail_hash.body)
    show_menu(resp_hash)
end

def channel_source(resp_hash) #uses show details to extract the streaming services show is available on
    channels = resp_hash["channels"].map{|source| source["name"]}
    if channels.empty?
        puts "There is no record of a channel for this show.".bold.colorize(:red)
    else
        puts "#{resp_hash["title"].titleize} is available on #{channels.join(", ").colorize(:red)}."
        sleep 2
        show_menu(resp_hash)
    end
end

def show_starring_cast(resp_hash) #uses show details to extract starring cast and character names
    if resp_hash["cast"].empty?
        puts "There is no cast record found for this show.".bold.colorize(:red)
        sleep 2
        show_menu(resp_hash)
    else
        puts resp_hash["cast"].first(3).map{|source| source["character_name"].length > 0 ? "#{source["name"].colorize(:light_red)}, starred as #{source["character_name"].colorize(:light_red)}" : "#{source["name"].colorize(:light_red)}"}
        sleep 2
        show_menu(resp_hash)
    end
end

def show_overview(resp_hash)
    puts resp_hash["overview"]
    sleep 2
    show_menu(resp_hash)
end

def show_menu(resp_hash)
    prompt = TTY::Prompt.new
    choice = prompt.select("What would you like to know about this show?".colorize(:light_blue)) do |menu|
        menu.choice name: 'What channel is this show on?', value: 1
        menu.choice name: 'Who stars in this show?', value: 2
        menu.choice name: 'What is this show about?', value: 3
        menu.choice name: 'Search again', value: 4
        menu.choice name: 'Exit', value: 5
    end
    if choice == 1
        channel_source(resp_hash)
    elsif choice == 2
        show_starring_cast(resp_hash)
    elsif choice == 3
        show_overview(resp_hash)
    elsif choice == 4
        sleep 1
        title_search
    else
        puts "Thank you, come again!".bold
    end
end
