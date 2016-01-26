require 'bundler/setup'
require 'csv'
require 'json'

df = CSV.read('data/kladr.csv', headers: true)

File.write 'data/kladr.json',
  df.map{|row|
    [
      row['code'],
      {
        code: row['code'],
        level: row['level'].to_i,
        type: row['type'],
        name: row['name'],
        district: row['district'],
        
        region: row['region_code'] && {
          code: row['region_code'],
          name: row['region_name'],
          wikiname: row['region_wikiname'],
        },

        raion: row['raion_code'] && {
          code: row['raion_code'],
          name: row['raion_name'],
        },

        city: row['city_code'] && {
          code: row['city_code'],
          name: row['city_name'],
        }
      }.reject{|k,v| !v}
    ]
  }.to_h.to_json

settlements = df.
  group_by{|r| r['name']}.
  map{|n, g| [n, g.sort_by{|r| [r['level'], r['code']]}.first]}.
  sort

File.write 'data/settlement2region.json',
  settlements.map{|n, r| [n, r['region_name']]}.to_h.to_json

File.write 'data/settlement2region2.json',
  settlements.map{|n, r| [n, r['region_wikiname']]}.to_h.to_json

File.write 'data/settlement2district.json',
  settlements.map{|n, r| [n, r['district']]}.to_h.to_json

cities = df.
  select{|r| r['level'] <= '3'}.
  group_by{|r| r['name']}.
  map{|n, g| [n, g.sort_by{|r| [r['level'], r['code']]}.first]}.
  sort

File.write 'data/city2region.json',
  cities.map{|n, r| [n, r['region_name']]}.to_h.to_json

File.write 'data/city2region2.json',
  cities.map{|n, r| [n, r['region_wikiname']]}.to_h.to_json

File.write 'data/city2district.json',
  cities.map{|n, r| [n, r['district']]}.to_h.to_json
