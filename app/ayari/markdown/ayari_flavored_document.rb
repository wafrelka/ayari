require 'kramdown'


module Ayari
	module Markdown

		class AyariFlavoredDocument

			PARAGRAPH_ELEMENT = 'section'

			attr :doc

			def initialize(kram_doc)

				AyariFlavoredDocument.transform_document_tree(kram_doc.root)
				@doc = kram_doc

			end

			def self.transform_document_tree(node)

				node.children.each do |ch|
					transform_document_tree(ch)
				end

				group_paragraphs(node)

			end

			def self.extract_tags(text)

				mo = /^(.+) +\{((\.|#)\S+( (\.|#)\S+)*)\}$/.match(text)
				return [text, [], []] if mo.nil?

				head_text = mo.captures[0]
				tags = mo.captures[1].split(' ')
				class_tags = tags.select{ |t| t[0] == '.' }.map{ |t| t[1..-1] }
				id_tags = tags.select{ |t| t[0] == '#' }.map{ |t| t[1..-1] }

				[head_text, class_tags, id_tags]

			end

			def self.transform_header(header)

				return if header.children.empty?

				last_ch = header.children[-1]
				return if last_ch.type != :text

				text = last_ch.value
				new_text, class_tags, id_tags = extract_tags(text)

				last_ch.value = new_text
				[class_tags, id_tags]

			end

			def self.group_paragraphs(node)

				new_children = []
				stack = [[0, new_children]]

				node.children.each do |ch|

					if ch.type != :header
						stack[-1][1] << ch
						next
					end

					class_tags, id_tags = transform_header(ch)

					level = ch.options[:level]

					header = Kramdown::Element.new(:header, nil, {}, ch.options)
					header.children = ch.children

					p_options = { category: :block, content_model: :block }
					p_attr = ch.attr
					p_attr.merge!({'class' => class_tags.join(' ')}) if ! class_tags.empty?
					p_attr.merge!({'id' => id_tags.join(' ')}) if ! id_tags.empty?
					paragraph = Kramdown::Element.new(:html_element, PARAGRAPH_ELEMENT, p_attr, p_options)
					paragraph.children << header

					while stack[-1][0] >= level
						stack.pop
					end

					stack[-1][1] << paragraph
					stack << [level, paragraph.children]

				end

				node.children = new_children

			end

		end

	end
end
