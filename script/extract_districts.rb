require 'bundler/setup'
require 'infoboxer'
require 'csv'

page = Infoboxer.wp(:ru).get('Федеральные_округа_Российской_Федерации')

REMOVE = Regexp.union(
  /^Республика/, /Республика$/,
  /(автономная )?область$/,
  /(автономный )?округ$/,
  /край$/,
)

TO_KLADR = {
  'Северная Осетия' => 'Северная Осетия - Алания',
  'Ханты-Мансийский автономный округ — Югра' => 'Ханты-Мансийский Автономный округ - Югра',
  'Саха (Якутия)' => 'Саха /Якутия/',
  'Чувашская' => 'Чувашская Республика -' # What's wrong with you, kladr???
}

def wiki2kladr(str)
  res = str.gsub(REMOVE, '').strip
  TO_KLADR[res] || res
end

CSV.open('script/data/districts.csv', 'wb') do |csv|
  page.sections('Список округов').sections.each do |sec|
    district = sec.heading.text.sub(' ФО', '').strip
    next if district.include?('Крымский')
    regions = sec.
      lookup(:UnorderedList).first.
      lookup(:Wikilink).map(&:text).
      reject{|t| t == 'Город федерального значения'}.
      map{|t| t.gsub(/[[:space:]]/, ' ').strip}.
      map{|t| [t, wiki2kladr(t)]}.
      each do |wiki, kladr|
        csv << [district, wiki, kladr]
      end
  end
end
