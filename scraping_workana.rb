require 'open-uri'
require 'rubygems'
require 'active_record'
require 'byebug'
require './freelancer'
require 'nokogiri'

ActiveRecord::Base.establish_connection(
  :adapter=> "postgresql",
  :host => "localhost",
  :database=> "workana",
  :username => "postgres",
  :password => "123456"
)
root_url = "https://www.workana.com/freelancers"
country = "AR"
page_count = 1
exist_workers = true

while exist_workers do

    page = Nokogiri::HTML(open("#{root_url}?country=#{country}&page=#{page_count}"))

    workers = page.css('#workers > .worker-item')
    worker_info = {}

    if workers.count > 0

        workers.each do |worker|
            numbers_info = worker.css('.worker-details > p > span')

            worker_info[:platform] = "workana"
            worker_info[:country] = country
            worker_info[:name] = worker.css('h3 > a').text
            worker_info[:url] = worker.css('h3 > a').first.attributes["href"].text if worker.css('h3 > a').count > 0
            worker_info[:pro] = (worker.css(".pro-label").count > 0)
            worker_info[:score] = worker.css('span .stars-bg').first.attributes["title"].text.split(" ").first if worker.css('span .stars-bg').count > 0
            worker_info[:description] = worker.css('.worker-description').text.strip
            worker_info[:skills] = worker.css('.skills > .expander > a').map{|skill| skill.text}
            worker_info[:level] = worker.css('.medals').text.strip
            worker_info[:hour_value] = worker.css('.price').text.split(" ").last.to_f
            worker_info[:photo] = worker.css('.profile-photo > a > img').first.attributes["src"].text if worker.css('.profile-photo > a > img').count > 0
            if numbers_info.count > 0
                worker_info[:projects] = numbers_info[0].text.split(": ").last
                worker_info[:hours] = numbers_info[2].text.split(": ").last
                worker_info[:last_login] = numbers_info[3].text.strip.split(": ").last
                worker_info[:account_creation] = numbers_info[4].text.strip.split(": ").last
            end
            begin
                search_freelancer = Freelancer.where(url: worker_info[:url])
                if search_freelancer.count == 1
                    search_freelancer.first.update(worker_info)
                else
                    Freelancer.create(worker_info)
                end
            rescue Exception => e
                puts e.message
            end
        end
        sleep(5)
    else
        exist_workers = false
    end
    puts "Page #{page_count} processed"
    page_count += 1
end
puts Freelancer.count