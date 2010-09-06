#!/usr/bin/env ruby
# encoding: utf-8

require 'rubygems'
require 'sinatra'

ALLOWED_WORDS = %w(ADJ ADV NC NMEA NMON NP ORD PE PNC UMMX VCLIfin VCLIger VCLIinf VEadj VEfin VEger VEinf VHadj VHfin VHger VHinf VLadj VLfin VLger VLinf VMadj VMfin VMger VMinf VSadj VSfin VSger VSinf)

def get_tagged file_path
  tagged = `sh /opt/tree-tagger/cmd/tree-tagger-spanish #{file_path}`.split("\n").map do |x|
    cols = x.split("\t")
    
    if ALLOWED_WORDS.index(cols[1])
       cols[2] == "<unknown>" ? cols[0] : cols[2]
    else
      "--NOVAL--"
    end
  end
  tagged.select{|x| x!="--NOVAL--"}
  tagged.join("\n")
end

def get_freqs tagged
  f={}
  tagged.delete("\r.,;:¡!¿?()$_@#\"").gsub("|","\n").gsub("~","\n").split("\n").each do |x|
    x = x.downcase.gsub(/^-/,"").gsub(/-$/,"")
    next if x.empty?
    f[x].nil? ? f[x] = 1 : f[x] += 1
  end    
  num_words = f.size.to_f
  
  f.merge(f){|k,v| {:freq_abs => v, :freq_rel => v/num_words}}
end

def get_freqs_diff freqs1, freqs2
  df = {}
  freqs2.merge(freqs2) do |word, values|
    df = freqs1[word].nil? ? values[:freq_rel]*freqs1.size : values[:freq_rel]/freqs1[word][:freq_rel]
    {:freq_abs => values[:freq_abs], :freq_rel => values[:freq_rel], :freq_diff => df}
  end
end

 get '/?' do
   erb :upload
 end

 post '/?' do
   @freqs1 = get_freqs get_tagged params[:file1][:tempfile].path
   @freqs2 = get_freqs get_tagged params[:file2][:tempfile].path
   @df1a2 = get_freqs_diff @freqs1, @freqs2
   @df2a1 = get_freqs_diff @freqs2, @freqs1
 
   erb :results

 end
