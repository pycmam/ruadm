require 'bundler/setup'
require 'daru'

kladr = Daru::DataFrame.from_csv('script/data/kladr_parsed.csv',
      headers: true,
      converters: [],
      encoding: 'UTF-8')

      # mindblowingly slow!
      #.filter(:row){|row|
        #row[:actuality] == 'actual'
      #}

kladr = kladr.where(kladr[:actuality].eq('actual')).
          delete_vector(:actuality)

wiki = Daru::DataFrame.from_csv('script/data/districts.csv',
      headers: ['district', 'region_wikiname', 'region_name'],
      converters: [],
      encoding: 'UTF-8')

joined = kladr.join(wiki, on: [:region_name], how: :left)
joined.write_csv('data/kladr.csv', headers: true, converters: [])
