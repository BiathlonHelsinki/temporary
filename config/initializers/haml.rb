ActiveSupport.on_load(:action_vew) do
  Haml::Template.options[:encoding] = 'utf-8'
end