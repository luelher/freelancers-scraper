require 'open-uri'
require 'rubygems'
require 'active_record'
require 'byebug'
require './freelancer'
require 'nokogiri'
require 'net/http'
require 'json'

ActiveRecord::Base.establish_connection(
  :adapter=> "postgresql",
  :host => "localhost",
  :database=> "workana",
  :username => "postgres",
  :password => "123456"
)
root_url = "https://www.freelancer.com/ajax/directory/getFreelancer.php"
profiel_url = "https://www.freelancer.es/u/"
country = "Venezuela"
page_count = 75
limit = 100
exist_workers = true

while exist_workers do

    uri = URI("#{root_url}?countries%5B%5D=#{country}&limit=#{limit}&offset=#{page_count*limit}")
    response = Net::HTTP.get(uri)
    freelancers = JSON.parse(response)
    worker_info = {}
    workers = freelancers["users"]

    if workers.count > 0

        workers.each do |worker|

            search_freelancer = Freelancer.where(url: profiel_url + worker["username"])

            unless search_freelancer.count == 1

                worker_info[:platform] = "freelancer"
                worker_info[:country] = country
                worker_info[:name] = worker["username"]
                worker_info[:url] = profiel_url + worker["username"]
                worker_info[:pro] = false
                worker_info[:score] = worker["score"].to_i
                worker_info[:description] = worker["about"]
                worker_info[:skills] = worker["top_skills"]
                worker_info[:level] = ""
                worker_info[:hour_value] = worker["hourlyrate"].to_i
                worker_info[:photo] = worker["profile_logo"]
                worker_info[:projects] = worker["jobs"].count if worker["jobs"]
                worker_info[:hours] = 0

                begin
                    page = Nokogiri::HTML(open(worker_info[:url]))
                    member_since = page.css('.profile-membership-length')
                rescue
                    member_since = nil
                end

                worker_info[:last_login] = nil # From Profile
                worker_info[:account_creation] = member_since.text.strip if member_since # From Profile

                begin
                    if search_freelancer.count == 1
                        search_freelancer.first.update(worker_info)
                    else
                        Freelancer.create(worker_info)
                    end
                    puts "/#{worker["username"]}"
                rescue Exception => e
                    puts e.message
                end
                sleep(0.2)
            else
                puts "find it /#{worker["username"]}"
            end

        end
    else
        exist_workers = false
    end

    puts "Page #{page_count + 1} processed"
    page_count += 1
    
end
puts Freelancer.count