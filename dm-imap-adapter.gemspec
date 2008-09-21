Gem::Specification.new do |s|
  s.name = %q{dm-imap-adapter}
  s.version = "0.9.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Chris Van Pelt"]
  s.autorequire = %q{dm-imap-adapter}
  s.date = %q{2008-09-21}
  s.description = %q{A DataMapper adapter to IMAP}
  s.email = %q{vanpelt@gmail.com}
  s.extra_rdoc_files = ["README.markdown", "LICENSE"]
  s.files = ["LICENSE", "README.markdown", "Rakefile", "lib/dm-salesforce.rb", "lib/salesforce_api.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://www.vandev.com}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A DataMapper adapter to IMAP}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<dm-core>, ["~> 0.9.4"])
      s.add_runtime_dependency(%q<extlib>, ["~> 0.9.4"])
    else
      s.add_dependency(%q<dm-core>, ["~> 0.9.4"])
      s.add_dependency(%q<extlib>, ["~> 0.9.4"])
    end
  else
    s.add_dependency(%q<dm-core>, ["~> 0.9.4"])
    s.add_dependency(%q<extlib>, ["~> 0.9.4"])
  end
end
