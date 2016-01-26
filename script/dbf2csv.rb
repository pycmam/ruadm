require 'bundler/setup'
require 'dbf'
require 'fileutils'
require 'csv'

table = DBF::Table.new('script/data/KLADR.DBF')

FileUtils.mkdir_p 'script/data'

CSV.open("script/data/kladr.csv", "wb") do |csv|
  table.each do |rec|
    next if rec.code.start_with?('91') || rec.code.start_with?('92')
    csv << [rec.name.force_encoding('CP866').encode('UTF-8'), rec.code]
  end
end


