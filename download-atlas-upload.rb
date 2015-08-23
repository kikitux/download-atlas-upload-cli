require "rubygems/package"
require "json"
require "net/http"
require 'open-uri'

uri = URI.parse("https://api.github.com/repos/hashicorp/atlas-upload-cli/releases/latest")

http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true

request = Net::HTTP::Get.new(uri.request_uri)
response = http.request(request)

if response.code == "200"
  result = JSON.parse(response.body)
  tag_name = result["tag_name"].tr('a-zA-Z', '')
  tarfile = "atlas-upload-cli_#{tag_name}_linux_amd64"
  url = "https://github.com/hashicorp/atlas-upload-cli/releases/download/v#{tag_name}/#{tarfile}.tar.gz"

  open("#{tarfile}.tar.gz", 'wb') do |file|
    file << open(url).read
  end

  file = "atlas-upload"

  Gem::Package::TarReader.new( Zlib::GzipReader.open "#{tarfile}.tar.gz") do |tar|
    tar.each do |entry|
      if entry.file? and entry.full_name == "#{tarfile}/#{file}"
        File.open file, "wb" do |f|
          f.print entry.read
        end
        FileUtils.chmod 0755, file
      end
    end
  end

  FileUtils.rm "#{tarfile}.tar.gz" if File.exists?("#{tarfile}.tar.gz")
end
