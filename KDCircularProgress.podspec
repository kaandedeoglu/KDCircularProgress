Pod::Spec.new do |s|
  s.name = 'KDCircularProgress'
  s.version = '1.5.2'
  s.license = 'MIT'
  s.summary = 'A circular progress view with gradients written in Swift'
  s.homepage = 'https://github.com/kaandedeoglu/KDCircularProgress'
  s.authors = { 'Kaan Dedeoglu' => 'kaandedeoglu@me.com' }
  s.source = { :git => 'https://github.com/kaandedeoglu/KDCircularProgress.git', :tag => s.version }

  s.ios.deployment_target = '8.0'

  s.source_files = 'KDCircularProgress/*.swift'
  s.requires_arc = true
end
