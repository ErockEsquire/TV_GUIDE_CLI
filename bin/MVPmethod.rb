require_relative './methods.rb'

class String
    def titleize
      self.split(" ").map{|word| word.capitalize}.join(" ")
    end
end

puts "Enter movie title"
p origin_title = gets.chomp
title = origin_title.gsub(/\s+/, "")

search = RestClient.get("http://api-public.guidebox.com/v2/search?type=movie&field=title&query=#{title}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
resp_hash = JSON.parse(search.body)
title = resp_hash["results"].map{|movie| "#{movie["title"]}, #{movie["release_year"]}"}

prompt = TTY::Prompt.new
choice = (prompt.select("Which title?", title))

list_choice = choice.gsub(/\s+/, "").sub(/,\d+/, "")
choice_search = RestClient.get("http://api-public.guidebox.com/v2/search?type=movie&field=title&query=#{list_choice}&limit=10&api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
choice_hash = JSON.parse(choice_search.body)
p id = choice_hash["results"].first["id"]

show_hash = RestClient.get("http://api-public.guidebox.com/v2/movies/#{id}?api_key=84b68f0497dc6bc45b5e600947b3156bf9c7743c")
resp_hash = JSON.parse(show_hash.body)
p services = resp_hash["subscription_web_sources"].map{|source| source["display_name"]}
puts "#{origin_title.titleize} is available on #{services.join(", ")}."