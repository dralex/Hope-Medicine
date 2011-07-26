# -*- coding: utf-8 -*-

require 'id'

APP_TITLE = 'МЕДИЦИНСКИЙ ТЕРМИНАЛ'
SERVER_URL = 'http://192.168.1.1/medic/medic.cgi'
IMAGES_URL = 'http://192.168.1.1/medic/images/'

class MedClient < Shoes
	url '/',					:index
	url '/check/([A-Fa-f\d]+)',	:check
	url '/analyse/([A-Fa-f\d]+)/(\d+)', :analyse
	url '/citology/([A-Fa-f\d]+)/(\d+)', :citology
	url '/hormonal/([A-Fa-f\d]+)/(\d+)', :hormons
	url '/genetic/([A-Fa-f\d]+)/(\d+)',	:genetic
	url '/scanning/([A-Fa-f\d]+)', :scanning
	url '/scanres/([A-Fa-f\d]+)/(\w+)/([\d,]+)', :scanning_result

	def index
		stack(:margin_top => 250) {
			title(code('Медицинский анализатор'), :align => 'center')
			flow(:margin_left => 200) {
				para code('Введите код: ')
				@codeedit = edit_line(:width => 350)
				@codeedit.text = ID.encode(0, 0, 3, [24])
			}
			button('Начать расшифровку', :margin_left => 300) {
				visit("/check/#{@codeedit.text}") if @codeedit.text =~ /^[A-Fa-f\d]+$/
			}
		}
	end

	def check(codeline)
		unless ID.check(codeline)
			alert 'Введен неверный код!'
			visit('/')
			return
		end

		para(code('Производится первичный анализ образца...'), :align => 'center')

		download("#{SERVER_URL}?check_id=#{codeline}") { |dump|
			case dump.response.body
			when /^BAD$/
				alert 'Введен неверный код!'
				visit('/')
			when /^EMPTY$/
				alert 'Образец израсходован полностью!'
				visit('/')
			when /^SIZE=(\d+)$/
				size = $1.to_i
				code = codeline
				visit("/analyse/#{code}/#{size}")
			when /^SCAN$/
				visit("/scanning/#{code}")
			else
				alert 'Неверный запрос!'
				visit('/')
			end
		}
	end

	def analyse(code, size)
		begin
			data = ID.decode code
		rescue Exception => e
			alert "Введен неверный код!"
			visit('/')			
		end		
		analysis = data[0]
		size = size.to_i

		if analysis == 0
			# анализ крови
			stack(:margin_top => 250) {
				title(code('Анализ крови'), :align => 'center')
				para(code("Для анализа доступно #{size} мл крови." + ((size > 0) ? "Выберите анализ из списка:" : "")), :align => 'center')
				stack(:margin_left => 300) {
					if size >= 1 then
						flow { @r1 = radio :analysis; para code("Цитологический анализ (1 мл)") } 
						if size >= 5 then
							flow { @r2 = radio :analysis; para code("Гормональный анализ (5 мл)") }
							if size >= 5 then
								flow { @r3 = radio :analysis; para code("Генетический анализ (5 мл)") }
							end
						end
					end
				}
				if size > 0 
					flow(:margin_left => 200) {
						button('Произвести анализ') {
							if @r1.checked?
								para(code('Производится цитологический анализ образца...'), :align => 'center')
								download("#{SERVER_URL}?citology=#{code}") { |dump|
									result_id = dump.response.body
									if result_id.nil? or not (result_id.strip =~ /^\d+$/)
										alert 'Ошибка в проведении анализа!'
										visit('/')
									else
										result_id.strip!
										visit("/citology/#{code}/#{result_id}") 	
									end
								}
							end
							if @r2.checked?
								para(code('Производится гормональный анализ образца...'), :align => 'center')
								download("#{SERVER_URL}?hormonal=#{code}") { |dump|
									result_id = dump.response.body
									if result_id.nil? or not (result_id.strip =~ /^\d+$/)
										alert 'Ошибка в проведении анализа!'
										visit('/')
									else
										result_id.strip!
										visit("/hormonal/#{code}/#{result_id}") 
									end
								}
							end
							if @r3.checked?
								para(code('Производится генетический анализ образца...'), :align => 'center')
								download("#{SERVER_URL}?genetic=#{code}") { |dump|
									result_id = dump.response.body
									if result_id.nil? or not (result_id.strip =~ /^\d+$/)
										alert 'Ошибка в проведении анализа!'
										visit('/')
									else
										result_id.strip!
										visit("/genetic/#{code}/#{result_id}") 
									end
								}
							end
						} 
						button("Вернуться") {
							visit('/')
						}
					}
				else
					flow(:margin_left => 350) {
						button("Вернуться") {
							visit('/')
						}
					}
				end
			}
		else
			# вывести результаты сканирования
		end
	end

	def citology(code, result)
		@result = result
		stack {
			@par = para(code('Результаты цитологического анализа:'), :align => 'center')
			@image = image("#{IMAGES_URL}/#{@result}.jpg", :margin_left => 50)
			flow {
				@but_new = button("Новый анализ (-1 мл)") {
					@par.text = code('Производится новый анализ крови...')
					download("#{SERVER_URL}?citology=#{code}") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if result == 'EMPTY'
								alert('Образец исчерпан!')
								@but_new.hide
							elsif not result =~ /^\d+$/
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
								@but_color.each { |b| b.show }
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				button("Перетряхнуть") {
					@par.text = code('Производится перетряхивание образца...')
					download("#{SERVER_URL}?citology=#{code}&result=#{@result}&operation=shuffle") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if not (result =~ /^\d+$/)
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				@but_color = []
				@but_color.push button("Окраска эритроцитов") {
					@par.text = code('Производится окраска эритроцитов в образце...')
					download("#{SERVER_URL}?citology=#{code}&result=#{@result}&operation=color0") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if not result =~ /^\d+$/
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
								@but_color.each { |b| b.hide }
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				@but_color.push button("Окраска по Ром.-Гимзе") {
					@par.text = code('Производится окраска образца...')
					download("#{SERVER_URL}?citology=#{code}&result=#{@result}&operation=color1") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if not result =~ /^\d+$/
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
								@but_color.each { |b| b.hide }
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				@but_color.push button("Окраска по Ром.-Райту") {
					@par.text = code('Производится окраска образца...')
					download("#{SERVER_URL}?citology=#{code}&result=#{@result}&operation=color2") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if not result =~ /^\d+$/
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
								@but_color.each { |b| b.hide }
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				@but_color.push button("Окраска рад. Тихмянова") {
					@par.text = code('Производится окраска образца...')
					download("#{SERVER_URL}?citology=#{code}&result=#{@result}&operation=color3") { |dump|
						result = dump.response.body
						if result.nil?
							alert 'Ошибка в проведении анализа!'
							visit('/')
						else
							result.strip!
							if not result =~ /^\d+$/
								alert 'Ошибка в проведении анализа!'
								visit('/')							
							else
								@result = result
								@image.path = "#{IMAGES_URL}/#{@result}.jpg"
								@but_color.each { |b| b.hide }
							end
							@par.text = code('Результаты цитологического анализа:')
						end
					}
				}
				button("Вернуться") {
					visit("/check/#{code}")
				}
			}
			@state = para ''
		}
	end

	def hormons(code, result)
		hormon_names = {
			:aldosterone => 'AL - Альдостерон',
			:kortisole => 'KO - Кортизол',
			:adrenaline => 'AD - Адреналин',
			:noradrenaline => 'NO - Норадреналин',
			:tiroxine => 'T4 - Тирокин',
			:triodtironine => 'T3 - Трийодтиронин',
			:paratireotide => 'PA - Паратиреоидный гормон',
			:insuline => 'IN - Инсулин',
			:glukasone => 'GL - Глюкагон',
			:somatostatine => 'SO - Соматостатин',
			:melatonine => 'ME - Мелатонин',
			:timopoetin => 'TI - Тимопоэтин',
			:gastrine => 'GA - Гастрин',
			:leptine => 'LE - Лептин'
		}
		hormons = hormon_names.keys.collect{|k| k.to_s}.sort

		stack {
			@par = para(code('Результаты гормонального анализа:'), :align => 'center', :margin_top => 100)
			@image = image("#{IMAGES_URL}/#{result}.jpg", :margin_left => 50)
			flow(:margin_left => 50) {
				text = []
				hormons.size.times { |i|
					text.push "#{hormon_names[hormons[i].to_sym]}"
				}
				para(code(text.join(', ')))
			}
			button("Вернуться", :margin_left => 350) {
				visit("/check/#{code}")
			}
		}
	end

	def genetic(code, result)
		stack {
			@par = para(code('Результаты генетического анализа:'), :align => 'center')
			@image = image("#{IMAGES_URL}/#{result}.jpg", :margin_left => 50)
			flow(:margin_left => 100) {
				para code('Введите хромосомный набор: ')
				@chromedit = edit_line(:width => 50)
				@chromedit.text = ''
				button("Запросить информацию") {
					@info_par.text = code('Запрос информации...')
					chrom = @chromedit.text.to_i
					if chrom.nil? or chrom <= 0 or chrom > 23 then
						#...
					else
						download("#{SERVER_URL}?genetic=#{code}&info=#{chrom}") { |dump|
							result = dump.response.body
							if result.nil? or result.empty? or result.strip == 'BAD'
								alert 'Ошибка в проведении анализа!'
								visit('/')
							else
								@info_par.text = code(result.strip)
								@chromedit.text = ''
							end
						}
					end
				}
			}
			button("Вернуться", :margin_left => 350) {
				visit("/check/#{code}")
			}
			@info_par = para('', :align => 'center')
		}
	end

	def scanning(code)
		@organs = {
			:head => ['Голова'],
			:bowels => ['Кишечник'],
			:lungs => ['Легкие'],
			:liver => ['Печень'],
			:kidney => ['Почки'],
			:heart => ['Сердце']
		}
		stack {
			title(code('Сканирование:'), :align => 'center')
			para(code('Выберите орган для осмотра:'), :align => 'center')
			stack(:margin_left => 400) {
				@organs.each_key { |o|
					flow { @organs[o].push radio :org; para code(o[0]) }
				}
			}
			flow {
				button("Результаты сканирования", :margin_left => 150) {
					res = nil
					@organs.each_key { |o|					
						if o[1].checked? then
							res = o
							break
						end
					}
					unless res.nil?
						@par.text = code('Получение результатов сканирования...')
						download("#{SERVER_URL}?scan=#{code}&organ=#{res}") { |dump|
							result = dump.response.body
							if result.nil? or result.empty? or result.strip == 'BAD'
								alert 'Ошибка в проведении анализа!'
								visit('/')
							else
								visit("/scanres/#{code}/#{res}/#{result.strip}")
							end
						}
					end
				}				
				button("Вернуться", :margin_left => 150) {
					visit('/')
				}
			}
			@par = para('')
		}
	end

	def scanning_result(code, organ, results)
		organs = {
			:head => 'Голова',
			:bowels => 'Кишечник',
			:lungs => 'Легкие',
			:liver => 'Печень',
			:kidney => 'Почки',
			:heart => 'Сердце'
		}
		@result_ids = results.split(',')
		@current = 0
		stack {
			title(code("Результаты сканирования: #{organs[organ.to_sym]}"), :align => 'center')
			@image = image("#{IMAGES_URL}/scan/#{@result_ids.first}.jpg", :margin_left => 200)
			flow(:margin_left => 350) {
				button('Следующая') {
					if @current < @result_ids.size - 1 then
						@current += 1
						@image.path = "#{IMAGES_URL}/scan/#{@result_ids[@current]}.jpg"
					end
				}
				button('Предыдущая') {
					if @current > 0 then
						@current -= 1
						@image.path = "#{IMAGES_URL}/scan/#{@result_ids[@current]}.jpg"
					end
				}
			}
			button("Вернуться", :margin_left => 350) {
				visit("/scanning/#{code}")
			}
		}
	end
	
end

Shoes.app(:title => APP_TITLE, :width => 900, :height => 800)

