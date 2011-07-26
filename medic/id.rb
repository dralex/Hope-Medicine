# -*- coding: utf-8 -*-
# здесь находится генератор уникальных идентификаторов для результатов сканирования
#
# типы анализов:
# 0. анализ крови
# 1. сканирование организма
#
# существуют следующие классы пациентов:
# 0. местные жители (молодые)
# 1. местные жители (гиперактивные)
# 2. местные жители (старые)
# 3. земляне с биоблокадой
# 4. земляне без биоблокады
# 
# пол:
# 0. мужской
# 1. женский
#
# список номеров болезней, которые есть у пациента (не более 10 штук)

class ID
	HASH_STRING = "test hash"
	
	def initialize
	end

	def ID.encode(analysis, sex, klass, deseases)
		n = deseases.size

		raise "Too much deseases" if n >= 10

		s1 = ((rand(4) << 2) | (analysis << 1) | sex).to_s(16)
		s2 = ((rand(1) << 4) | (klass & 0x7)).to_s(16)
		s3 = (n & 0xf).to_s(16)

		result = dummy(1) + s2  + dummy(1) + s1 + dummy(1) + s3
		
		n.times { |i|
			result += dummy(1)
			d = deseases[i]
			result += sprintf('%02x', deseases[i])
		}
	
		result += dummy(30 - n * 3)
		result.upcase!
		result += sprintf('%04X', (result + HASH_STRING).hash & 0xffff)
		result
	end

	def ID.check(s, kind = :any)
		string = s.upcase
		hash_string = string[36, 4]
		if string.size == 40 and ((string[0, 36] + HASH_STRING).hash & 0xffff) == hash_string.hex then
			return true if kind == :any

			s1 = string[3, 1]
			num = s1.hex
			analysis = (num >> 1) & 1

			if (analysis == 0 and kind == :blood) or (analysis == 1 and kind == :scan) 
				return true
			else
				return false
			end
		else
			return false
		end
	end

	def ID.decode(s)
		raise "Bad string" unless check(s)
		string = s.upcase

		s1 = string[3, 1]
		s2 = string[1, 1]
		s3 = string[5, 1]
		
		num = s1.hex
		analysis = (num >> 1) & 1
		sex = num & 1
		num = s2.hex
		klass = num & 0x7

		raise "Bad class" if klass >= 6

		num = s3.hex
		n = num & 0xf
		
		raise "Too much deseases" if n >= 10

		deseases = []
		n.times { |i|
			d = string[7 + i * 3, 2].hex
			deseases.push d
		}
		
		[analysis, sex, klass, deseases]
	end

	def ID.dummy(len)
		s = ''
		len.times {
			s += rand(16).to_s(16)
		}
		s
	end
end
