
class Log

	FILENAME = 'server.log'

	def initialize
	end

	def write(s)
		@file = File.new(FILENAME, File::WRONLY | File::APPEND)
		@file.puts "#{Time.now.to_s} #{s}"
		@file.close
	end
end
