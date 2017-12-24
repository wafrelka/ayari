require 'kramdown'
require 'yaml'
require 'hashie'


module Ayari
	module Processor

		class InvalidContent < ArgumentError; end

		module MarkdownProcessor

			YAML_BLOCK_MARK = '---'
			YAML_TEMPLATE_PATH_ELEM = 'template'
			YAML_MD_OPTS_ELEM = 'opts'

			def self.parse_markdown_parameters(params)

				if ! params.is_a?(Hash)
					raise InvalidContent.new('invalid parameters')
				end

				template_path = params.dig(YAML_TEMPLATE_PATH_ELEM)
				md_opts = params.dig(YAML_MD_OPTS_ELEM) || {}
				opts = params

				if !(template_path.is_a?(String) && md_opts.is_a?(Hash))
					raise InvalidContent.new
				end

				opts = Hashie.symbolize_keys(opts)
				md_opts = Hashie.symbolize_keys(md_opts)

				[template_path, md_opts, opts]

			end

			def self.parse_markdown_text(txt)

				lines = txt.each_line.to_a
				block_last_idx = lines.drop(1).find_index{ |line| line.chomp == YAML_BLOCK_MARK }

				if lines.first&.chomp != YAML_BLOCK_MARK || block_last_idx.nil?
					raise InvalidContent.new('parameter block not found')
				end

				yaml_lines = lines[1..block_last_idx]
				yaml_txt = yaml_lines.join()
				body_lines = lines[(block_last_idx + 2)..-1]
				body_txt = body_lines.join()

				begin
					params = YAML.load(yaml_txt)
				rescue StandardError => err
					raise InvalidContent.new('invalid YAML format')
				end

				template_path, md_opts, opts = parse_markdown_parameters(params)

				[body_txt, template_path, md_opts, opts]

			end

			def self.process_text(txt)

				body, template_path, md_opts, opts = parse_markdown_text(txt)
				md_opts[:auto_ids] ||= false

				begin
					kram_doc = Kramdown::Document.new(body, **md_opts)
				rescue StandardError => err
					raise InvalidContent.new("HTML text generation failed: #{err.message}")
				end

				content = kram_doc.to_html
				opts.merge!({content: content})

				[template_path, opts]

			end

		end

	end

end
