# -*- coding: utf-8 -*-

require 'RMagick'
require 'id'
require 'deseases'
require 'log'

class GeneticsAnalysis

	RESULT_SIZE_X = 800
	RESULT_SIZE_Y = 600
	BORDER = 10
	ROW_HEIGHT = (RESULT_SIZE_Y - BORDER * 2) / 2
	ROW_CENTER = ROW_HEIGHT / 2 - BORDER
	CHROMO_COUNT_ROW = 12
	CHROMO_BOX_WIDTH = (RESULT_SIZE_X - BORDER * 2)/ CHROMO_COUNT_ROW
	CHROMO_WIDTH = CHROMO_BOX_WIDTH / 5
	
	def initialize

		# 0-21 normal chromosoms
		# 22 - Y
		# 23 - X

		@genetic_norm = [
						 [138, 146],
						 [104, 165],
						 [103, 116],
						 [56, 152],
						 [52, 145],
						 [71, 119],
						 [63, 112],
						 [50, 103],
						 [51, 101],
						 [48, 102],
						 [60, 89],
						 [36, 105],
						 [0, 99],
						 [0, 96],
						 [0, 91],
						 [42, 56],
						 [29, 64],
						 [23, 63],
						 [34, 45],
						 [33, 38],
						 [0, 42],
						 [0, 40],
						 [18, 54],
						 [61, 100]
		]

#		@genetic_norm.each { |pair|
#			pair[0] = pair[0] * 3 / 4
#			pair[1] = pair[1] * 3 / 4
#		}

		@deseases = Deseases.new
	end

	def generate_data(code)
		analysis, sex, klass, deseases = ID.decode code

		result = generate_norm(code)

		deseases.each { |d|
			gen = @deseases.get(d)[:genetics]
			next if gen.empty?
			next if gen.has_key? :sex and gen[:sex] != sex
			changes = gen[:changes]
			changes.each_key { |chrom|
				c = changes[chrom]
				case c[0]
				when :add
					what = c[1]
					result[chrom - 1].push @genetic_norm[what]
				when :sub
					what = c[1]
					if result[chrom - 1][0][0] == @genetic_norm[what][0] and result[chrom - 1][0][1] == @genetic_norm[what][1] then
						result[chrom - 1].delete_at(0)
					else
						result[chrom - 1].delete_at(1)
					end
				when :del
					if c[1] == :up then
						result[chrom - 1][0][0] -= c[2]
						result[chrom - 1][1][0] -= c[2]
					else
						result[chrom - 1][0][1] -= c[2]
						result[chrom - 1][1][1] -= c[2]
					end
				when :dup
					if c[1] == :up then
						result[chrom - 1][0][0] += c[2]
						result[chrom - 1][1][0] += c[2]
					else
						result[chrom - 1][0][1] += c[2]
						result[chrom - 1][1][1] += c[2]
					end
				when :trans
					what = c[2]
					minus = c[3]
					plus = c[4]
					if c[1] == :up then
						result[chrom - 1][0][0] += plus - minus
						result[chrom - 1][1][0] += plus - minus
					else
						result[chrom - 1][0][1] += plus - minus
						result[chrom - 1][1][1] += plus - minus
					end
				end
			}
		}

		return result
	end

	def get_info(code, number)

		data = generate_data(code)
		norm = generate_norm(code)
		analysis, sex, klass, deseases = ID.decode code
		
		pair = data[number - 1]
		the_norm = norm[number - 1]
		
		good = true
		if pair.size != the_norm.size then
			good = false
		else 
			pair.each_index { |j|
				if pair[j] != the_norm[j] then
					good = false
					break
				end
			}
		end

		if good then
			return "Хромосомный набор #{number}#{number == 23 ? ' (половой)' : ''} в норме."
		else
			res = []
			deseases.each { |d|
				gen = @deseases.get(d)[:genetics]
				
				next if gen.empty?
				next if gen.has_key? :sex and gen[:sex] != sex
				next if not gen.has_key? :changes or not gen[:changes].has_key? number
				c = gen[:changes][number]
				case c[0]
				when :add
					res.push 'полисомия'
				when :sub
					res.push 'моносомия'
				when :del
					what = c[1]
					if c[1] == :up then
						res.push 'делеция короткого плеча'
					else
						res.push 'делеция длинного плеча'					
					end
				when :dup
					what = c[1]
					if c[1] == :up then
						res.push 'дупликация короткого плеча'
					else
						res.push 'дупликация длинного плеча'					
					end
				when :trans
					what = c[2]
					if c[1] == :up then
						res.push "транслокация короткого плеча с #{what + 1}-й хромосомой"
					else
						res.push "транслокация длинного плеча с #{what + 1}-й хромосомой"
					end
				end				
			}
			"Хромосомный набор #{number}#{number == 23 ? ' (половой)' : ''} имеет изменения: #{res.join(', ')}."
		end	
	end

	def generate_norm(code)
		analysis, sex, klass, deseases = ID.decode code

		result = []

		@genetic_norm.each_index { |i|
			if i <= 21 then
				result.push [@genetic_norm[i].dup, @genetic_norm[i].dup]
			else
				if sex == 0 then
					result.push [@genetic_norm[23].dup, @genetic_norm[22].dup]
				else
					result.push [@genetic_norm[23].dup, @genetic_norm[23].dup]
				end
				break
			end
		}		
		return result
	end

	def generate_image(norm, data, name)

		result = Magick::Image.new(RESULT_SIZE_X, RESULT_SIZE_Y) {
			self.background_color = 'white'
		}
		
		gc = Magick::Draw.new
		gc.stroke_width(2)
		gc.text_align(Magick::CenterAlign)

		gc.pointsize = 14
		gc.line(BORDER, BORDER + ROW_CENTER, RESULT_SIZE_X - BORDER, BORDER + ROW_CENTER)
		gc.line(BORDER, BORDER + ROW_CENTER + ROW_HEIGHT, RESULT_SIZE_X - BORDER, BORDER + ROW_CENTER + ROW_HEIGHT)

		max_height = [0, 0]
		data.each_index { |i|
			pair = data[i]
			pair.each_index { |j|
				v = pair[j][1]
				max_height[i / 12] = v if v > max_height[i / 12]
			}
		}
		norm.each_index { |i|
			pair = data[i]
			pair.each_index { |j|
				v = pair[j][1]
				max_height[i / 12] = v if v > max_height[i / 12]
			}
		}

		gc.stroke('#777777')
		gc.fill('white')
		norm.each_index { |i|
			pair = norm[i]
			
			chromo_space = (CHROMO_BOX_WIDTH - CHROMO_WIDTH * pair.size) / 3
			bar_x = BORDER + (i % 12) * CHROMO_BOX_WIDTH + chromo_space
			bar_y = BORDER + ROW_CENTER + (i > 11 ? ROW_HEIGHT : 0)
 
			pair.each_index { |j|
				chromo = pair[j]
				if chromo[0] > 0 then
					gc.rectangle(bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y - chromo[0],
								 bar_x + j * (CHROMO_WIDTH + chromo_space) + CHROMO_WIDTH, bar_y)
				else
					radius = CHROMO_WIDTH / 2
					gc.circle(bar_x + radius + j * (CHROMO_WIDTH + chromo_space), bar_y - radius,
							  bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y - radius)
				end
				gc.rectangle(bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y,
							 bar_x + j * (CHROMO_WIDTH + chromo_space) + CHROMO_WIDTH, bar_y + chromo[1])
			}
		}

		gc.stroke('black')
		data.each_index { |i|
			pair = data[i]
			the_norm = norm[i]
			
			chromo_space = (CHROMO_BOX_WIDTH - CHROMO_WIDTH * pair.size) / 3
			bar_x = BORDER + (i % 12) * CHROMO_BOX_WIDTH + chromo_space
			bar_y = BORDER + ROW_CENTER + (i > 11 ? ROW_HEIGHT : 0)

			good = true
			if pair.size != the_norm.size then
				good = false
			else 
				pair.each_index { |j|
					if pair[j] != the_norm[j] then
						good = false
						break
					end
				}
			end
 
			if good then
				gc.fill('green')
				gc.fill_opacity(0.5)
			else
				gc.fill('red')
				gc.fill_opacity(0.5)
			end

			pair.each_index { |j|
				chromo = pair[j]
				if chromo[0] > 0 then
					gc.rectangle(bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y - chromo[0],
								 bar_x + j * (CHROMO_WIDTH + chromo_space) + CHROMO_WIDTH, bar_y)
				else
					radius = CHROMO_WIDTH / 2
					gc.circle(bar_x + radius + j * (CHROMO_WIDTH + chromo_space), bar_y - radius,
							  bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y - radius)
				end
				gc.rectangle(bar_x + j * (CHROMO_WIDTH + chromo_space), bar_y,
							 bar_x + j * (CHROMO_WIDTH + chromo_space) + CHROMO_WIDTH, bar_y + chromo[1])
			}
			gc.fill('black')
			gc.text(bar_x - chromo_space + CHROMO_BOX_WIDTH / 2, bar_y + max_height[i / 12] + 20, (i + 1).to_s)
		}

		gc.draw(result)
		result.write(name + '.jpg')
	end

end
