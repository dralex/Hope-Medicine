# -*- coding: utf-8 -*-
# Biochemical analysis

require 'id'
require 'RMagick'
require 'deseases'

class BiochemAnalysis

	IMAGES_DIR = 'src/'
	IMAGE_SIZE = 100
	HALF_IMAGE_SIZE = IMAGE_SIZE / 2
	RESULT_SIZE_X = 800
	RESULT_SIZE_Y = 600
	TOTAL_AMOUNT = 100
	DX = RESULT_SIZE_X + IMAGE_SIZE
	DY = RESULT_SIZE_Y + IMAGE_SIZE
	TRIES = 50

	def initialize()
		@images = {}

		@images[:basophil] = Magick::ImageList.new(IMAGES_DIR + '01.png')
		@images[:eosinophil] = Magick::ImageList.new(IMAGES_DIR + '02.png')
		@images[:erythrocyte] = [3, 4, 5, 6, 7].collect { |i| Magick::ImageList.new(IMAGES_DIR + "0#{i}.png") }
		@images[:leukocyte] = Magick::ImageList.new(IMAGES_DIR + '17.png')
		@images[:lifebacteria] = Magick::ImageList.new(IMAGES_DIR + '09.png')
		@images[:lymphocyte] = Magick::ImageList.new(IMAGES_DIR + '10.png')
		@images[:monocyte] = Magick::ImageList.new(IMAGES_DIR + '11.png')
		@images[:neutrophil] = Magick::ImageList.new(IMAGES_DIR + '12.png')
		@images[:shit] = [13, 14].collect { |i| Magick::ImageList.new(IMAGES_DIR + "#{i}.png") }
		@images[:bigspore] = Magick::ImageList.new(IMAGES_DIR + '15.png')
		@images[:bacteria] = Magick::ImageList.new(IMAGES_DIR + '16.png')
		@images[:tlymphocyte] = Magick::ImageList.new(IMAGES_DIR + '08.png')
		@images[:trombocyte] = [18, 19, 20].collect { |i| Magick::ImageList.new(IMAGES_DIR + "#{i}.png") }
		@images[:spore] = Magick::ImageList.new(IMAGES_DIR + '21.png')
		@images[:baderythrocyte] = [22, 23, 24].collect { |i| Magick::ImageList.new(IMAGES_DIR + "#{i}.png") }

		@images.values.each { |image|
			if image.kind_of? Array then
				image.each { |i|
					i.background_color = 'none'
				}
			else
				image.background_color = 'none'
			end
		}

		@names = {}

		@names[:erythrocyte] = 'Эритроцит'
		@names[:baderythrocyte] = 'Эритроцит'
		@names[:trombocyte] = 'Тромбоцит'
		@names[:leukocyte] = 'Лейкоцит'

		@names[:neutrophil] = 'Нейтрофильные гранулоциты'
		@names[:basophil] = 'Базофильные гранулоциты'
		@names[:eosinophil] = 'Эозинофильные гранулоциты'

		@names[:monocyte] = 'Агранулоциты Мононуклеарный фагоцит'
		@names[:lymphocyte] = 'Агранулоциты B-лимфоциты'
		@names[:tlymphocyte] = 'Агранулоциты T-лимфоциты'

		@names[:lifebacteria] = 'Бактерия жизни'
		@names[:shit] = 'Неопределенная клетка в крови'
		@names[:spore] = 'Неопределенная клетка в крови'
		@names[:bigspore] = 'Неопределенное тело в крови'
		@names[:bacteria] = 'Неопределенное тело в крови (вероятно, бактерия)'

		@dist = {}
		@dist[:erythrocyte] = IMAGE_SIZE / 4
		@dist[:baderythrocyte] = IMAGE_SIZE / 4
		@dist[:trombocyte] = IMAGE_SIZE / 8
		@dist[:leukocyte] = IMAGE_SIZE / 4
		@dist[:neutrophil] = IMAGE_SIZE / 3
		@dist[:basophil] = IMAGE_SIZE / 3
		@dist[:eosinophil] = IMAGE_SIZE / 3
		@dist[:monocyte] = IMAGE_SIZE / 3
		@dist[:lymphocyte] = IMAGE_SIZE / 3
		@dist[:tlymphocyte] = IMAGE_SIZE / 3
		@dist[:lifebacteria] = IMAGE_SIZE / 4
		@dist[:shit] = IMAGE_SIZE / 8
		@dist[:spore] = IMAGE_SIZE / 8
		@dist[:bigspore] = IMAGE_SIZE / 3
		@dist[:bacteria] = IMAGE_SIZE / 4

		# кровяные тела в мкл
		# 3,5 - 5 * 10^6
		# 4 - 9 * 10^3
		# 150-400 * 10^3
	
		@blood_norms = [
		{  # надежда, ребенок
			:erythrocyte => [110, 120],
			:trombocyte => [90, 100],
			:shit => [40, 80],
			:neutrophil => [28, 32],
			:basophil => [2, 4], 
			:eosinophil => [3, 5], 
			:lymphocyte => [14, 16], 
			:monocyte => [4, 6], 
			:tlymphocyte => [14, 16],
			:spore => [50, 80]
		}, # надежда, отрок
		{ 
			:erythrocyte => [110, 130],
			:trombocyte => [60, 80],
			:shit => [50, 100],
			:neutrophil => [28, 32],
			:basophil => [2, 5], 
			:eosinophil => [3, 5], 
			:lymphocyte => [14, 16], 
			:monocyte => [4, 6], 
			:tlymphocyte => [14, 16],
			:spore => [10, 20],
			:bigspore => [1, 5]
		}, # надежда, старик
		{ 
			:erythrocyte => [100, 110],
			:trombocyte => [50, 70],
			:shit => [100, 150],
			:neutrophil => [27, 30],
			:basophil => [3, 4], 
			:eosinophil => [3, 5], 
			:lymphocyte => [14, 16], 
			:monocyte => [4, 6], 
			:tlymphocyte => [14, 16],
			:spore => [1, 5],
			:bigspore => [10, 20]
		}, # человек
		{ 
			:erythrocyte => [110, 140],
			:trombocyte => [50, 70],
			:shit => [30, 70],
			:neutrophil => [23, 35],
			:basophil => [0, 1], 
			:eosinophil => [0, 3], 
			:lymphocyte => [8, 18], 
			:monocyte => [1, 3], 
			:tlymphocyte => [10, 16],
			:lifebacteria => [2, 8]
		}, # человек без биоблокады
		{ 
			:erythrocyte => [110, 140],
			:trombocyte => [50, 70],
			:shit => [40, 80],
			:neutrophil => [24, 36],
			:basophil => [0, 1], 
			:eosinophil => [0, 3], 
			:lymphocyte => [10, 20], 
			:monocyte => [1, 4], 
			:tlymphocyte => [11, 17]
		}]

		@deseases = Deseases.new
	end
		
	def generate_data(code)
		data = ID.decode(code)
		analysis, sex, klass, deseases = data

		blood = {}
		@blood_norms[klass].each { |k, v|
			diff = v[1] - v[0]
			smalldiff = (diff / 10).to_i
			val = v[0] + rand(diff)
			val += rand(smalldiff) - rand(smalldiff) if smalldiff >= 1
			blood[k] = val
		}

		deseases.each { |d|
			b = @deseases.get(d)[:blood]
			b.each_key { |k|
				v = b[k]
				diff = v[1] - v[0]
				val = rand(diff) + v[0]
				if blood.has_key? k then
					blood[k] += val
				else
					blood[k] = val
				end
				blood[k] = 0 if blood[k] < 0
			}
		}
		return blood
	end

	def generate_image(blood, name, paints)		
		result = Magick::Image.new(RESULT_SIZE_X, RESULT_SIZE_Y) {
			self.background_color = 'white'
		}

		past_coords = []

		i = 0	
		key = :erythrocyte
		dist = @dist[key]
		x, y = 0, 0
		blood[key].times {
			i += 1
			TRIES.times {
				x = rand(DX) - HALF_IMAGE_SIZE
				y = rand(DY) - HALF_IMAGE_SIZE
				good = true
				past_coords.each { |c|
					if (c[0] - x).abs < IMAGE_SIZE and (c[1] - y).abs < IMAGE_SIZE then
						if ((c[0] - x) ** 2 + (c[1] - y) ** 2) < ((c[2] + dist) ** 2) then
							good = false
							break
						end
					end
				}
				break if good
			}
			past_coords.push([x, y, dist])

			image = @images[key][rand(@images[key].size)]

			if paints.include? 0 then
				image = image.level_colors('red', 'white')				
			end

			angle = rand(360)
			scale = rand * 0.4 + 0.7
			result.composite!(image.scale(scale).rotate(angle), x, y, Magick::OverCompositeOp)
		}

		past_coords = []
		x, y = 0, 0
		blood.keys.sort {|k1,k2| @dist[k2] <=> @dist[k1] }.each { |key|
			next if key == :erythrocyte
			dist = @dist[key]
			blood[key].times {
				i += 1
				TRIES.times {
					x = rand(DX) - HALF_IMAGE_SIZE
					y = rand(DY) - HALF_IMAGE_SIZE
					good = true
					past_coords.each { |c|
						if (c[0] - x).abs < IMAGE_SIZE and (c[0] - y).abs < IMAGE_SIZE then
							if ((c[0] - x) ** 2 + (c[1] - y) ** 2) < ((c[2] + dist) ** 2) then
								good = false
								break
							end
						end
					}
					break if good
				}
				past_coords.push([x, y, dist])
	
				color = nil
	
				if @images[key].kind_of? Array then
					image = @images[key][rand(@images[key].size)]
				else
					image = @images[key]
				end

				if paints.include? 0 and key == :baderythrocyte then
					image = image.level_colors('red', 'white')
				end
				if paints.include? 1 and [:neutrophil, :basophil, :eosinophil].include? key then
					image = image.level_colors('#3300aa', 'white')
				end
				if paints.include? 2 and [:lymphocyte, :monocyte, :tlymphocyte].include? key then
					image = image.level_colors('#661144', 'white')				
				end
				if paints.include? 3 and [:lifebacteria, :bigspore].include? key then
					image = image.level_colors('#337700', 'white')				
				end
			
				angle = rand(360)
				scale = rand * 0.2 + 0.8
				result.composite!(image.scale(scale).rotate(angle), x, y, Magick::OverCompositeOp)
			}
		}
#		result.display
		result.write(name + ".jpg")
	end

end



