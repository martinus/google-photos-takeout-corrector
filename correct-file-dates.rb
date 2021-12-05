#!/bin/env ruby
require "json"
require "date"

if ARGV.empty?
    puts "usage: #{__FILE__} <path>"
    puts "parses all .json files and updates file date based on photoTakenTime/timestamp"
    exit
end

# Parse all .json files and corrects image file dates
dir = ARGV.shift

# Create a list of all files and their correct time
file_to_time = {}
Dir.glob("#{dir}/**/*.json") do |f|
    basename = File.basename(f)
    next if basename =~ /metadata.*\.json/
    next if basename == "print-subscriptions.json"
    next if basename == "user-generated-memory-titles.json"
    next if basename == "shared_album_comments.json"

    begin
        json = JSON.load_file(f)
        t = json["photoTakenTime"]["timestamp"].to_i
        if t.nil? || t==0
            raise "no valid t: #{t}"
        end

        media_file = "#{File.dirname(f)}/#{json['title']}"
        if !File.exist?(media_file)
            # safety check to see if the media file actually exists
            raise "File '#{media_file}' doesn't exist!"
        end

        file_to_time[media_file] = t
    rescue => err
        STDERR.puts "#{f}: #{err}"
        raise
    end
end

# safety check to see if any file exists that doesn't have a .json file
Dir.glob("#{dir}/**/*") do |f|
    next if File.directory?(f)
    next if File.extname(f) == ".json"
    p f
    if !file_to_time.has_key?(f)
        raise "Cannot find '#{f}'. File.exist? #{File.exist?(f)}"
    end
end

# finally, seems that no files are missing => update everything
puts "Updating date of #{files_and_time.size} files..."
files_and_time.each do |file, t|
    #File.lutime(t, t, media_file)
    puts "TODO"
end

puts "done!"
