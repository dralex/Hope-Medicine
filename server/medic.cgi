#!/usr/bin/ruby
# -*- coding: utf-8 -*-

DATABASE_FILE = 'codes.txt'
ANALYSE_DEFAULT_SIZE = 10
CITOLOGY_COST = 1
HORMONAL_COST = 5
GENETIC_COST = 5

IMAGES_DIR = 'images/'

require 'cgi'
require 'db'
require 'id'
require 'biochemical'
require 'hormonal'
require 'genetics'
require 'scanning'
require 'log'

def result(str)
	$log.write "result: #{str}"
	puts "Content-Type: text/plain\n\n"
	puts str
	exit 0
end

srand Time.now.to_i
cgi = CGI.new
db = Database.new DATABASE_FILE
$log = Log.new

$log.write "New request: #{cgi.params.inspect}"

# ПРОВЕРКА КОДА И ВЫДАЧА ОСТАТКА КРОВИ ПО АНАЛИЗАМ
value = cgi.params['check_id'].to_s
unless value.empty?
	code = value.strip
	$log.write "checking id #{code}"
	unless ID.check(code, :blood) then
		if ID.check(code, :scan) then
			result 'SCAN'
		else
			result 'BAD'
		end
	end
	res = db.findlast code
	if res.nil? then
		db.add([code, ANALYSE_DEFAULT_SIZE, 'new'])
		result "SIZE=#{ANALYSE_DEFAULT_SIZE}"
	else
		if res[1] == 0 then
			result "EMPTY"
		else
			result "SIZE=#{res[1]}"
		end
	end
end

# ЦИТОЛОГИЧЕСКИЙ АНАЛИЗ
value = cgi.params['citology'].to_s
unless value.empty?
	code = value.strip
	$log.write "citology #{code}"
	unless ID.check(code, :blood)
		result 'BAD'
	end	

	value = cgi.params['result'].to_s
	unless value.empty?
		result_id = value.strip.to_i
	else 
		result_id = nil
	end

	value = cgi.params['operation'].to_s
	unless value.empty?
		operation = value.strip
	else 
		unless result_id.nil?
			result 'WRONG PARAMS'
		end
	end

	ba = BiochemAnalysis.new

	if result_id.nil? then
		result_id = (Time.now.to_i << 10) + rand(1024)
		res = db.findlast code
		if (not res.nil?) and res[1].to_i == 0 then
			result 'EMPTY'
		end
		blood =	ba.generate_data(code)
		ba.generate_image(blood, "#{IMAGES_DIR}/#{result_id}", [])
		write_string = "citology:#{result_id}:#{blood.keys.collect { |k| "#{k}=#{blood[k]}" }.join(',')}:"
		if res.nil? then
			db.add([code, ANALYSE_DEFAULT_SIZE - CITOLOGY_COST, write_string])
		else
			db.add([code, res[1].to_i - CITOLOGY_COST, write_string])
		end
		result(result_id.to_s)
	else 
		res = db.findlastres code, result_id
		if res.nil?
			result 'ERROR'
		end
		if res[1].to_i < 0 then
			result 'EMPTY'
		end

		$log.write "Processing result #{result_id}"

		blood_data = res[4].split(',')
		blood = {}
		blood_data.each { |pair|
			name, val = pair.split('=')
			blood[name.to_sym] = val.to_i
		}

		operations = res[5].nil? ? [] : res[5].split(',')
		operations.push operation

		color = nil

		operations.each { |op|
			if op =~ /^color(\d)$/
				color = $1.to_i
			end
		}

		result_id = (Time.now.to_i << 10) + rand(1024)
		$log.write "New result #{result_id}"
		ba.generate_image(blood, "#{IMAGES_DIR}/#{result_id}", (color.nil? ? [] : [color]))
		write_string = "citology:#{result_id}:#{blood.keys.collect { |k| "#{k}=#{blood[k]}" }.join(',')}:#{operations.join(',')}"
		db.add([code, res[1].to_i, write_string])
		$log.write "Result size: #{res[1]}"
		result(result_id.to_s)
	end
end

# ГОРМОНАЛЬНЫЙ АНАЛИЗ
value = cgi.params['hormonal'].to_s
unless value.empty?
	code = value.strip
	$log.write "hormonal: #{code}"
	unless ID.check(code, :blood) then
		result 'BAD'
	end	

	res = db.findlast code
	if (not res.nil?) 
		if res[1].to_i < HORMONAL_COST then
			result 'EMPTY'
		elsif res[2] == 'hormonal'
			$log.write 'Duplicate query'
			result res[3]
		end
	end
	h = HormonalAnalysis.new	
	result_id = (Time.now.to_i << 10) + rand(1024)
	$log.write "New result #{result_id}"
	hormons = h.generate_data(code)
	h.generate_image(hormons, "#{IMAGES_DIR}/#{result_id}")
	write_string = "hormonal:#{result_id}:#{hormons.keys.collect { |k| "#{k}=#{hormons[k]}" }.join(',')}"
	if res.nil? then
		db.add([code, ANALYSE_DEFAULT_SIZE - HORMONAL_COST, write_string])
	else
		db.add([code, res[1].to_i - HORMONAL_COST, write_string])
	end
	result(result_id.to_s)
end

# ГЕНЕТИЧЕСКИЙ АНАЛИЗ
value = cgi.params['genetic'].to_s
unless value.empty?
	code = value.strip
	$log.write "genetic: #{code}"
	unless ID.check(code, :blood) then
		result 'BAD'
	end	

	g = GeneticsAnalysis.new

	value = cgi.params['info'].to_s
	if value.strip =~ /^\d+$/
		info = value.strip.to_i
		gens = g.generate_data(code)
		str = g.get_info(code, info)
		result str
	end

	res = db.findlast code
	if (not res.nil?) 
		if res[1].to_i < GENETIC_COST then
			result 'EMPTY'
		elsif res[2] == 'genetic'
			$log.write 'Duplicate query'
			result res[3]
		end
	end
	result_id = (Time.now.to_i << 10) + rand(1024)
	$log.write "New result #{result_id}"
	gens = g.generate_data(code)
	norm = g.generate_norm(code)
#	$log.write "gen #{gens.inspect} #{norm.inspect}"
	g.generate_image(norm, gens, "#{IMAGES_DIR}/#{result_id}")
	write_string = "genetic:#{result_id}"
	if res.nil? then
		db.add([code, ANALYSE_DEFAULT_SIZE - GENETIC_COST, write_string])
	else
		db.add([code, res[1].to_i - GENETIC_COST, write_string])
	end
	result(result_id.to_s)
end

# СКАНИРОВАНИЕ
value = cgi.params['scan'].to_s
unless value.empty?
	code = value.strip
	$log.write "scanning: #{code}"
	unless ID.check(code, :scan) then
		result 'BAD'
	end	

	value = cgi.params['organ'].to_s
	unless value.empty?
		organ = value.strip
	else 
		result 'BAD'
	end
	
	res = db.findlast code
	if not res.nil? and res[1] == 'scanning' and res[2] == organ
		$log.write 'Duplicate scanning query'
		result res[3]
	end
	
	result_id = (Time.now.to_i << 10) + rand(1024)
	$log.write "New result #{result_id}"
	images = Scanning.new(code, organ).generate_images(IMAGES_DIR, result_id)
	list = images.join(',')
	db.add([code, 'scanning', organ, list])
	result(list)
end

result 'ERROR'
exit 0

