#! /usr/bin/ruby -w

require 'json'

fileName = ARGV[0];
jsonFile = File.open(fileName);
exit if (!jsonFile);
jsonData = jsonFile.read();
obj_lst = JSON.parse(jsonData);
obj_lst.each {|key, val|
    print("Key: #{key}, Val: #{val}\n");
}

