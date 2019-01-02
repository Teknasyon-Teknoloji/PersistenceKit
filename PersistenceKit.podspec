Pod::Spec.new do |s|
    s.name = "PersistenceKit"
    s.version = "1.2.1"
    s.summary = "
    Store and retrieve Codable objects to various persistence layers, in a couple lines of code! "
    s.description = <<-DESC
    You love Swift's Codable protocol and use it everywhere, who doesn't! Here is an easy and very light way to store and retrieve Codable objects to various persistence layers, in a couple lines of code!
    DESC

    s.homepage = "https://github.com/Teknasyon-Teknoloji/PersistenceKit"
    s.license = { :type => "MIT", :file => "LICENSE" }
    s.social_media_url = "http://www.teknasyon.com/"

    s.authors = { "Omar Albeik" => "https://twitter.com/omaralbeik" }

    s.module_name  = "PersistenceKit"
    s.source = { :git => "https://github.com/Teknasyon-Teknoloji/PersistenceKit.git", :tag => s.version }
    s.source_files = "Sources/**/*.swift"
    s.swift_version = "4.2"
    s.requires_arc = true

    s.ios.deployment_target = "8.0"
    s.osx.deployment_target = "10.10"
    s.tvos.deployment_target = "9.0"
    s.watchos.deployment_target = "2.0"
end
