$:.unshift(File.join(File.dirname(File.expand_path(__FILE__)), '..', 'app'))
require 'ayari'


if __FILE__ == $0

	if ARGV.length < 1
		puts "usage: #{$0} <target_markdown_path>"
		exit 1
	end

	path = ARGV[0]
	txt = File.read(path, encoding: "UTF-8")

	template_rel_path, opts = Ayari::Markdown::Processor::process_text(txt)

	puts "template_rel_path: #{template_rel_path}"
	opts.each do |key, value|
		if key != :content
			puts "option[#{key}] = #{value}"
		end
	end
	puts "content:"
	puts opts[:content]

end
