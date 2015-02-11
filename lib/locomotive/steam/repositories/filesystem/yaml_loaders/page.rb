module Locomotive
  module Steam
    module Repositories
      module Filesystem
        module YAMLLoaders

          class Page < Struct.new(:root_path, :default_locale, :cache)

            include YAMLLoaders::Concerns::Common

            def list_of_attributes
              cache.fetch('app/views/pages') { load_tree }
            end

            private

            def path
              @path ||= File.join(root_path, 'app', 'views', 'pages')
            end

            def load_tree
              {}.tap do |hash|
                each_file do |filepath, relative_path, fullpath, locale|

                  if leaf = hash[fullpath]
                    update(leaf, filepath, fullpath, locale)
                  else
                    leaf = build(filepath, fullpath, locale)
                  end

                  hash[fullpath] = leaf
                end
              end.values
            end

            def build(filepath, fullpath, locale)
              slug = fullpath.split('/').last
              attributes = load(filepath, true)

              {
                title:              { locale => attributes.delete(:title) || (default_locale == locale ? slug.humanize : nil) },
                slug:               { locale => attributes.delete(:slug) || slug },
                editable_elements:  { locale => attributes.delete(:editable_elements) },
                template_path:      { locale => filepath },
                _fullpath:          fullpath
              }.merge(attributes)
            end

            def update(leaf, filepath, fullpath, locale)
              slug = fullpath.split('/').last
              attributes = load(filepath, true)

              leaf[:title][locale] = attributes.delete(:title) || slug.humanize
              leaf[:slug][locale] = attributes.delete(:slug) || slug
              leaf[:editable_elements][locale] = attributes.delete(:editable_elements)
              leaf[:template_path][locale] = filepath

              leaf.merge!(attributes)
            end

            def each_file(&block)
              Dir.glob(File.join(path, '**', '*')).each do |filepath|
                next unless is_liquid_file?(filepath)

                relative_path = get_relative_path(filepath)

                fullpath, locale = relative_path.split('.')[0..1]
                locale = default_locale if template_extensions.include?(locale)

                yield(filepath, relative_path, fullpath, locale.to_sym)
              end
            end

            def is_liquid_file?(filepath)
              filepath =~ /\.(#{template_extensions.join('|')})$/
            end

            def get_relative_path(filepath)
              filepath.gsub(path, '').gsub(/^\//, '')
            end

          end

        end
      end
    end
  end
end
