# -*- coding: utf-8 -*-

require 'id'
require 'deseases'

srand Time.now.to_i

Shoes.app(:title => 'Генератор кодов', :width => 550, :height => 300) {
	@des = Deseases.new
	@selected = []
	stack {
		flow {
			para 'Тип анализа: '
			@r_analyse_blood = radio :analyse
			para 'анализ крови '
			@r_analyse_scan = radio :analyse
			para 'сканирование'
		}
		flow {
			para 'Пол: '
			@r_sex_male = radio :sex
			para 'мужской '
			@r_sex_female = radio :sex			
			para 'женский'
		}
		flow {
			para 'Тип: '
			@r_type = []
			['Н мол', 'Н пик а', 'Н пик б', 'Н стар', 'З бб', 'З без'].each { |t|
				@r_type.push radio :type
				para "#{t}; "
			}
		}
		flow {
			para 'Болезни: '
			@des_par = para ''
		}
		flow {
			ll = @des.list.sort
			@des_list = list_box :items => ll
			@des_list.choose(ll.first)
			button('Добавить') {
				unless @selected.include? @des_list.text
					alert(@selected.join(' '))
					@selected.push @des_list.text
					@des_par.text = @selected.join(' ')
				end
			}
			button('Очистить') {
				@selected = []
				@des_par.text = ''
			}
		}
		flow {
			para 'Количество: '
			@num_edit = edit_line
			@num_edit.text = '1'
		}
		button('Сгенерировать!') {
			if @num_edit.text =~ /^\d+$/
				count = @num_edit.text.to_i

				analysis = 0 if @r_analyse_blood.checked?
				analysis = 1 if @r_analyse_scan.checked?
				
				sex = 0 if @r_sex_male.checked?
				sex = 1 if @r_sex_female.checked?
				
				typ = nil
				@r_type.each_index { |i|
					if @r_type[i].checked? then
						typ = i
						break
					end
				}
				return if typ.nil?
				
				deseases = @selected.collect { |d|  @des.get_id(d) }				
				result = Array.new(count).collect { ID.encode(analysis, sex, typ, deseases) }.join("\n")
				alert(result)
			end
		}
	}
}



