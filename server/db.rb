class Database
	def initialize(name)
		@filename = name
	end

	def listlast
		file = File.new(@filename, 'r')
		return [] if file.nil?
		res = {}
		file.each_line { | line|
			row = line.strip.split(':')
			next if row.empty?
			res[row[0].to_i] = row
		}
		file.close
		return res
	end

	def add(row)
		file = File.new(@filename, 'a')
		file.puts row.join(':')
		file.close
	end
	
	def findlast(code)
		file = File.new(@filename, 'r')
		return nil if file.nil?
		res = nil
		file.each_line { | line|
			line.strip!
			next if line.empty?
			row = line.split(':')
			next if row.empty?
			if row[0] == code
				res = row
			end
		}
		file.close
		return res
	end

	def findlastres(code, result)
		file = File.new(@filename, 'r')
		return nil if file.nil?
		res = nil
		file.each_line { | line|
			line.strip!
			next if line.empty?
			row = line.split(':')
			next if row.empty?
			if row[0] == code and row[2] == 'citology' and row[3] == result.to_s
				res = row
			end
		}
		file.close
		return res
	end
end
