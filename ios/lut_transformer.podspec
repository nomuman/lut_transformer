Pod::Spec.new do |s|
  s.name             = 'lut_transformer'
  s.version          = '1.0.0'
  s.summary          = 'LUT video transformation plugin.'
  s.description      = <<-DESC
Applies LUT transformations to videos.
  DESC
  s.homepage         = 'https://github.com/nomuman/lut_transformer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Author' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform     = :ios, '11.0'
  s.swift_version = '5.0'
end
