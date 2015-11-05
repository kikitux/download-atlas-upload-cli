#!/usr/bin/env ruby

product="nomad"
binaryfile="nomad"
os="linux"                                                                                                                                                                                                                   
arch="amd64"

require "rubygems/package"                                                                                                                                                                                                   
require "json"                                                                                                                                                                                                               
require "net/http"                                                                                                                                                                                                           
require "open-uri"                                                                                                                                                                                                           
require "zip"

uri = URI.parse("https://releases.hashicorp.com/#{product}/index.json")

http = Net::HTTP.new(uri.host, uri.port)                                                                                                                                                                                     
http.use_ssl = true

request = Net::HTTP::Get.new(uri.request_uri)                                                                                                                                                                                
response = http.request(request)

if response.code == "200"                                                                                                                                                                                                    
  result = JSON.parse(response.body)                                                                                                                                                                                         
  versions = result["versions"]                                                                                                                                                                                              
  maxver = "0.0.0"                                                                                                                                                                                                           
  versions.each do |key, value|                                                                                                                                                                                              
    maxver = versions[key]["version"] if Gem::Version.new(maxver) < Gem::Version.new(versions[key]["version"])                                                                                                               
  end                                                                                                                                                                                                                        
  thisone = versions[maxver]["builds"].select { |builds| builds["os"] == os && builds["arch"] == arch}                                                                                                                       
  url = thisone[0]["url"]                                                                                                                                                                                                    
  filename = thisone[0]["filename"]
  
  if File.file? filename                                                                                                                                                                                                     
    puts "file #{filename} present"                                                                                                                                                                                          
  else                                                                                                                                                                                                                       
    open(filename, 'wb') do |file|                                                                                                                                                                                           
      file << open(url).read                                                                                                                                                                                                 
    end                                                                                                                                                                                                                      
  end
  
  file = binaryfile
  
  Zip::File.open(filename) do |zip|                                                                                                                                                                                          
    zip.each do |entry|                                                                                                                                                                                                      
      if entry.file? and entry.name == file                                                                                                                                                                                  
        File.open file, "wb" do |f|                                                                                                                                                                                          
          f.print entry.get_input_stream.read                                                                                                                                                                                
        end                                                                                                                                                                                                                  
        FileUtils.chmod 0755, file                                                                                                                                                                                           
      end                                                                                                                                                                                                                    
    end                                                                                                                                                                                                                      
  end
  
  FileUtils.rm filename if File.exists?(filename)                                                                                                                                                                            
  else
  puts "check product #{product} is valid"                                                                                                                                                                                   
end 
