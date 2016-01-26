require 'bundler/setup'
require 'daru'

kladr = Daru::DataFrame.from_csv('script/data/kladr_parsed.csv',
      headers: true,
      converters: [],
      encoding: 'UTF-8').
      filter(:row){|row|
        row[:type] == 'region' && row[:actuality] == 'actual'
      }

wiki = Daru::DataFrame.from_csv('script/data/districts.csv',
      headers: ['district', 'region-wiki', 'name'],
      converters: [],
      encoding: 'UTF-8')

joined = kladr.join(wiki, on: [:name], how: :outer)
p joined.filter(:row){|row| row[:code].nil?}
