Gem::Specification.new do |s|
  s.name        = 'surfacelab'
  s.version     = '0.0.1'
  s.date        = '2018-02-05'
  s.summary     = 'Surfacelab BeagleBone control lib'
  s.description = 'A Full Featured Beaglebone IO Gem'
  s.author      = 'Roman Kochkin'
  s.email       = 'electromanko@gmail.com'
  s.files       = `git ls-files`.split("\n")
  s.homepage    = 'https://github.com/electromanko/surfacelab'
  s.license     = 'GPL-3.0'
  s.add_dependency = 'spi'
  s.add_dependency = 'serialport'
  s.add_dependency = 'beaglebone', '~> 2.0.0'
end