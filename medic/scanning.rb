
require 'id'
require 'deseases'

class Scanning
	def initialize(organ, code)
		@code = code
		analysis, sex, klass, deseases = ID.decode(code)
		@deseases = deseases
		@data = generate_data(organ.to_sym, deseases)

		@base_images = nil
	end

	def generate_data(organ, deseases)
		res = []
		deseases.each { |d|
			next if d[:scan].empty?
			next unless d[:scan].has_key? organ
			res.push d[:scan][organ]
		}
		res
	end

	def generate_images(code, img_dir, first_id)
		
	end
end

