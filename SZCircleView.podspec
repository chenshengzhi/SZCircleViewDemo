
Pod::Spec.new do |s|

  s.name         = "SZCircleView"

  s.version      = "0.0.8"

  s.summary      = "circle scrollview"

  s.homepage     = "https://github.com/chenshengzhi/SZCircleViewDemo"

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "陈圣治" => "csz2136@163.com" }

  s.platform     = :ios, "6.0"

  s.source       = { :git => "https://github.com/chenshengzhi/SZCircleViewDemo.git", :tag => s.version.to_s }

  s.source_files = "SZCircleView/*.{h,m}"

  s.requires_arc = true

end
