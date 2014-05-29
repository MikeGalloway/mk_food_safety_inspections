#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
# has at least a table called data.
require 'scraperwiki'
require 'nokogiri'
require 'mechanize'
require 'open-uri'
require 'date'
require 'json'
require 'yaml'

id = "870"

# Milton Keynes 870
# Walsall 433

doc = Nokogiri::XML open("http://ratings.food.gov.uk/OpenDataFiles/FHRS#{id}en-GB.xml")

inspections = []

doc.search('EstablishmentDetail').each do |i|
   details = i.children.inject({}){|hsh,el| hsh[el.name] = el.inner_text;hsh}
   details["lat"] = i.search('Geocode Latitude').inner_text rescue nil
   details["lng"] = i.search('Geocode Longitude').inner_text rescue nil
   inspections << details
end

inspections.each do |i|
   if i["RatingValue"] == "Exempt"
      puts "skipping: Exempt id: " + i["FHRSID"] + "Name: " + i["BusinessName"]
      # skip
   elsif i["RatingValue"] == "AwaitingInspection"
      puts "skipping: Awaiting Inspection id: " + i["FHRSID"] + "Name: " + i["BusinessName"]
      # skip
   else   
    details = {}
    details[:id] = i["FHRSID"]
    details[:councilid] = i["LocalAuthorityBusinessID"]
    details[:date] = Date.parse(i["RatingDate"]) rescue nil
    details[:name] = i["BusinessName"]
    details[:link] = "http://ratings.food.gov.uk/business/en-GB/#{details[:id]}"
    address = [i["AddressLine1"], i["AddressLine2"], i["AddressLine3"], i["AddressLine4"], i["PostCode"]].compact.reject { |s| s.empty? }
    details[:address] = address.join(", ")
    details[:postcode] = i["PostCode"]
    details[:rating] = i["RatingValue"]
    details[:type] = i["BusinessType"]
    details[:rss_date] = details[:date].strftime("%A, %d %b %Y %H:%M:%S %Z")
    details[:lat] = i["lat"]
    details[:lng] = i["lng"]
     ScraperWiki.save([:id], details)
   end
end
