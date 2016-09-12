I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.default_locale = :en
I18n.available_locales = [:en]
I18n.fallbacks[:en] = [:en]


Globalize.fallbacks = {:en => [:en] }