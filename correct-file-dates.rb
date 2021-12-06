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

        # basename maximum 47 characters
        # don'T allow several unicode characters 

        json_title = json['title'].gsub(/[\u0026-\u0026\:]/, '_')
        title_ext = File.extname(json_title)
        if (title_ext == "")
            title_ext = ".jpg"
        end
        title_noext = json_title.delete_suffix(title_ext)
        title = title_noext[0...47] + title_ext

        media_file = "#{File.dirname(f)}/#{title}"

        found = false
        if File.exist?(media_file)
            file_to_time[media_file] = t
            found = true
        end

        # always try to add '(1)' before the suffix
        i = 1
        loop do
            title = "#{title_noext[0...47]}(#{i})#{title_ext}"
            media_file1 = "#{File.dirname(f)}/#{title}"

            #title = File.basename(f).delete_suffix('.json')
            #media_file = "#{File.dirname(f)}/#{title}"
            if !File.exist?(media_file1)
                break
            end

            file_to_time[media_file1] = t
            found = true
            i += 1
        end

        if found == false
            # safety check to see if the media file actually exists
            p f
            p File.dirname(f)
            p File.basename(f)
            raise "File '#{media_file}' doesn't exist!"
        end

        # check if there is a "-edited" version
        ext = File.extname(media_file)
        edited_media_file = "#{media_file.delete_suffix(ext)}-edited#{ext}"
        if File.exist?(edited_media_file)
            file_to_time[edited_media_file] = t
        end

        # check if it's an MVIMG file, and add the .MP4 as well
        if basename.start_with?('MVIMG')
            mvimg_file = "#{media_file.delete_suffix(ext)}.MP4"
            if File.exist?(mvimg_file)
                file_to_time[mvimg_file] = t
            end
        end

        if media_file.end_with?('MP.jpg')
            mp_file = media_file.delete_suffix('.jpg')
            if File.exist?(mp_file)
                file_to_time[mp_file] = t
            end
        end
    rescue => err
        STDERR.puts "#{f}: #{err}"
        raise
    end
end

# safety check to see if any file exists that doesn't have a .json file
Dir.glob("#{dir}/**/*") do |f|
    next if File.directory?(f)
    next if File.extname(f) == ".json"
    if !file_to_time.has_key?(f)
        STDERR.puts "Cannot find '#{f}'. File.exist? #{File.exist?(f)}"
    end
end

# finally, seems that no files are missing => update everything
puts "Updating date of #{file_to_time.size} files..."
file_to_time.each do |file, t|
    File.lutime(t, t, file)
    #puts "#{file}"
end

puts "done!"
