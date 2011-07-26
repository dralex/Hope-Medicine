# -*- coding: utf-8 -*-
# Hormonal analysis

require 'id'
require 'RMagick'
require 'deseases'

class HormonalAnalysis

	RESULT_SIZE_X = 800
	RESULT_SIZE_Y = 300
	BORDER = 20
	TEXT_HEIGHT = 40

	HUMAN_MIN = 10
	HUMAN_MAX = 20

	def initialize()
		
		@hormon_names = {
			:aldosterone => 'Альдостерон',
			:kortisole => 'Кортизол',
			:adrenaline => 'Адреналин',
			:noradrenaline => 'Норадреналин',
			:tiroxine => 'Тироксин (T3)',
			:triodtironine => 'Трийодтиронин (T4)',
			:paratireotide => 'Паратиреоидный гормон',
			:insuline => 'Инсулин',
			:glukasone => 'Глюкагон',
			:somatostatine => 'Соматостатин',
			:melatonine => 'Мелатонин',
			:timopoetin => 'Тимопоэтин',
			:gastrine => 'Гастрин',
			:leptine => 'Лептин'
		}

		@hormon_levels = [
			[20, 30], # надежда ребенок
			[40, 50], # надежда отрок
			[15, 25], # надежда старик
			[HUMAN_MIN, HUMAN_MAX], # землянин, ББ
			[HUMAN_MIN, HUMAN_MAX] # землянин, без
		]

		@deseases = Deseases.new
	end

	def generate_data(code)
		data = ID.decode(code)
		analysis, sex, klass, deseases = data

		levels = @hormon_levels[klass]
		hormons = {}
		@hormon_names.each_key { |key|
			diff = levels[1] - levels[0]
			minidiff = (diff / 10).to_i
			mimidiff = 2 if minidiff < 2
			val = rand(diff) + levels[0] + rand(minidiff) - rand(minidiff)
			hormons[key] = val
		}

		deseases.each { |d|
			h = @deseases.get(d)[:hormons]
			h.each_key { |k|
				v = h[k]
				diff = v[1] - v[0]
				val = rand(diff) + v[0]
				if hormons.has_key? k then
					hormons[k] += val
				else
					hormons[k] = val
				end
				hormons[k] = 1 if hormons[k] <= 0
			}
		}
		return hormons
	end

	def generate_image(hormons, name)
		
		max_value = 0
		hormons.each_key { |key|
			v = hormons[key]
			max_value = v if max_value < v
		}

		result = Magick::Image.new(RESULT_SIZE_X, RESULT_SIZE_Y) {
			self.background_color = 'white'
		}

		bar_wight = (RESULT_SIZE_X - BORDER * 2) / (hormons.size * 2 - 1)
		bar_height_max = (RESULT_SIZE_Y - BORDER * 2 - TEXT_HEIGHT)

		gc = Magick::Draw.new
		gc.fill_opacity(0.3)
		gc.stroke_width(2)
		gc.text_align(Magick::CenterAlign)

		l1, l2 = HUMAN_MIN, HUMAN_MAX

		gc.pointsize = 14
		gc.stroke('black')
		level_y = RESULT_SIZE_Y - BORDER - TEXT_HEIGHT - ((l1.to_f / max_value.to_f) * bar_height_max.to_f).to_i
		gc.text(BORDER - 7, level_y + 15, l1.to_s)
		gc.line(BORDER, level_y, RESULT_SIZE_X - BORDER, level_y)
		level_y = RESULT_SIZE_Y - BORDER - TEXT_HEIGHT - ((l2.to_f / max_value.to_f) * bar_height_max.to_f).to_i
		gc.text(BORDER - 7, level_y + 15, l2.to_s)
		gc.line(BORDER, level_y, RESULT_SIZE_X - BORDER, level_y)

		i = 0	
		hormons.each_key { |key|
			v = hormons[key]
			bar_height = ((v.to_f / max_value.to_f) * bar_height_max.to_f).to_i

			if (v >= l1 and v <= l2) then
				color = 'blue'
			else
				color = 'red'
			end

			base_bar_x = BORDER + 5 + i * bar_wight * 2
			base_bar_y = RESULT_SIZE_Y - BORDER - TEXT_HEIGHT
			
			gc.stroke(color)
			gc.fill(color)
			gc.rectangle(base_bar_x, base_bar_y - bar_height,
						 base_bar_x + bar_wight, base_bar_y)
			gc.stroke('none')
			gc.fill('black')

			text = key.to_s[0,2].upcase
			text = 'T3' if key == :tiroxine
			text = 'T4' if key == :triodtironine
			gc.text(base_bar_x + bar_wight / 2, base_bar_y + TEXT_HEIGHT / 2, text)
			gc.text(base_bar_x + bar_wight / 2, base_bar_y + TEXT_HEIGHT / 2 - bar_height, v.to_s)
			i += 1
		}

		gc.draw(result)
		result.write(name + '.jpg')
	end
end

