require 'open-uri'

def create_product(centor_x, centor_y, num=10)
  min_x = centor_x - (num / 2).to_i
  max_x = centor_x + (num / 2).to_i - 1

  min_y = centor_y - (num / 2).to_i
  max_y = centor_y + (num / 2).to_i - 1

  [*min_x..max_x].product([*min_y..max_y])
end

DEST_DIR = 'public/data/'

def load_and_save_map_data(type, zoom, x, y, ext)
  `mkdir -p "#{DEST_DIR}#{type}/#{zoom}/#{x}"`

  path = "#{type}/#{zoom}/#{x}/#{y}.#{ext}"

  data = open("http://cyberjapandata.gsi.go.jp/xyz/#{path}")
  File.binwrite(DEST_DIR + path, data.read)
end

targets = create_product(14275, 6533)

zoom = 14
type = 'relief'; ext = 'png'
targets.each {|(x, y)|
  load_and_save_map_data(type, zoom, x, y, ext)
  sleep(2)
}

zoom = 14
type = 'dem'; ext = 'txt'
targets.each {|(x, y)|
  load_and_save_map_data(type, zoom, x, y, ext)
  sleep(2)
}
