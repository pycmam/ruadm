require 'bundler/setup'
require 'fileutils'
require 'hashie'
require 'daru'

module KladrCode
  TYPES = [
    :region,
    :raion, # https://en.wikipedia.org/wiki/Raion
    :city,
    :settlement
  ]
  
  # Офиц.документация КЛАДР:
  #   “00” – актуальный объект (его наименование, подчиненность соответствуют состоянию на данный момент адресного пространства). 
  #   “01”-“50” – объект был переименован, в данной записи приведено одно из прежних его наименований (актуальный адресный объект присутствует в базе данных с тем же кодом, но с признаком актуальности “00”;
  #   “51” –  объект был переподчинен или влился в состав другого объекта (актуальный адресный объект определяется по базе Altnames.dbf);
  #   “52”-“98” – резервные значения признака актуальности;
  #   ”99” – адресный объект не существует, т.е. нет соответствующего ему актуального адресного объекта.
  ACTUALITIES = Hashie::Rash.new(
    0      => :actual,
    1..50  => :renamed,
    51     => :merged,
    52..98 => :reserve,
    99     => :nonexisting
  ).freeze

  COLUMNS = [:actuality, :level, :type, :region_code, :raion_code, :city_code]

  module_function
  def make_code(parts, level)
    return nil if parts[level] == '000' # если у города нет родительской области, напр.
    res = (parts[0..level] + ['000'] * (3 - level)).join + '00'
  end
  
  def parse(str)
    # Офиц.документация КЛАДР:
    #   СС РРР ГГГ ППП АА, где
    #   СС – код субъекта Российской Федерации (региона), коды регионов представлены в Приложении 2 к Описанию классификатора адресов Российской Федерации (КЛАДР);
    #   РРР – код района;
    #   ГГГ – код города;      
    #   ППП – код населенного пункта,
    #   АА – признак актуальности адресного объекта.
    *parts, actuality = str.scan(/^(..)(...)(...)(...)(..)$/).flatten
    level = parts.rindex{|part| part !~ /^0+$/}

    [
      ACTUALITIES[actuality.to_i], # actuality
      level + 1,
      TYPES[level],                # type name
      *(0...3).                    # list of parent codes
        map{|i|
          if i <= level
            make_code(parts, i)
          else
            nil
          end
        }
    ]
  end
end

df = Daru::DataFrame.from_csv('script/data/kladr.csv',
      headers: ['name', 'code'],
      converters: [],
      encoding: 'UTF-8')

parsed = Daru::DataFrame.rows(df[:code].map{|c| KladrCode.parse(c)})
parsed.vectors = KladrCode::COLUMNS # didn't work

i = 0
parsed.each_vector do |vector|
  df.add_vector(KladrCode::COLUMNS[i], vector)
  i += 1
end

names = df[:code].to_a.zip(df[:name].to_a).to_h


df.add_vector(:region_name,
  df[:region_code].map{|rc| rc && names[rc]}
)
df.add_vector(:raion_name,
  df[:raion_code].map{|rc| rc && names[rc]}
)
df.add_vector(:city_name,
  df[:city_code].map{|rc| rc && names[rc]}
)

df.write_csv('script/data/kladr_parsed.csv', headers: true, converters: [])
