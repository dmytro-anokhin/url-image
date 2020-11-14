Pod::Spec.new do |spec|
  spec.name         = 'URLImage'
  spec.version      = '2.1.7'
  spec.summary      = 'SwiftUI Image view that displays an image downloaded from URL.'

  spec.description  = <<-DESC
  URLImage is a SwiftUI view that displays an image downloaded from provided URL. URLImage manages downloading remote image and caching it locally, both in memory and on disk, for you.
                   DESC

  spec.homepage     = 'https://github.com/dmytro-anokhin/url-image'

  spec.license      = 'MIT'

  spec.author       = { 'Dmytro Anokhin' => '5136301+dmytro-anokhin@users.noreply.github.com' }

  spec.source       = { :git => 'https://github.com/dmytro-anokhin/url-image.git', :tag => "#{spec.version}" }

  spec.source_files  = 'Sources', 'Sources/**/*.{swift}'
  spec.exclude_files = 'Tests'

  spec.swift_versions = '5.3'

  spec.platforms = { :ios => '10.0', :tvos => '10.0', :osx => '10.12', :watchos => '3.0' }

  spec.subspec 'RemoteContentView' do |ss|
    ss.source_files = 'Dependencies/Sources/RemoteContentView/**/*.{swift}'
  end

  spec.subspec 'ImageDecoder' do |ss|
    ss.source_files = 'Dependencies/Sources/ImageDecoder/**/*.{swift}'
  end

  spec.subspec 'FileIndex' do |ss|
    ss.source_files = 'Dependencies/Sources/FileIndex/**/*.{swift}'
    ss.dependency 'URLImage/Log'
    ss.dependency 'URLImage/PlainDatabase'
    ss.dependency 'URLImage/Common'
  end

  spec.subspec 'PlainDatabase' do |ss|
    ss.source_files = 'Dependencies/Sources/PlainDatabase/**/*.{swift}'
  end

  spec.subspec 'DownloadManager' do |ss|
    ss.source_files = 'Dependencies/Sources/DownloadManager/**/*.{swift}'
    ss.dependency 'URLImage/Log'
  end

  spec.subspec 'Common' do |ss|
    ss.source_files = 'Dependencies/Sources/Common/**/*.{swift}'
  end

  spec.subspec 'Log' do |ss|
    ss.source_files = 'Dependencies/Sources/Log/**/*.{swift}'
  end

end
