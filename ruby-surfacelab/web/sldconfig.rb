require 'json'
require 'yaml'
require 'benchmark'
require "ipaddress"

class SLDConfig
    
    def self.load_config(path, type=:YAML)
        if type == :JSON
            JSON.parse(File.read(path))
        elsif type == :YAML
            YAML.load_file(path)
        end
    end

    def self.save_config(config, path, type=:YAML)
        if validate(config)
            if type == :JSON
                File.open(path, 'w') { |file| file.write(JSON.pretty_generate(config)) }
            elsif type == :YAML
                File.open(path, 'w') { |file| file.write(config.to_yaml) }
            elsif type== :SLD
                str=""
                config['port'].each do |port|
                    str+="-P #{port['tcp_port']} -D #{port['sys_path']}"
                    str+= " -S #{port['speed']} -b #{port['data_bits']} -p #{port['parity']}"
                    str+= " -s #{port['stop_bits']}"
                    str+=" --segment-delay #{port['delay_us']}" if port['delay_us']!=0
                    str+=" --segment-size #{port['delay_segment']}" if port['delay_segment']!=0
                    str+=" --event-rx-led #{port['rx_led'].to_i}" if port['rx_led'].to_i>0
                    str+=" --event-tx-led #{port['tx_led'].to_i}" if port['tx_led'].to_i>0
                    port['gpio_high'].each do |gpio|
                        str+=" --gpio-high #{gpio}"
                    end
                    port['gpio_low'].each do |gpio|
                        str+=" --gpio-low #{gpio}"
                    end
                    str+="\n"
                end
                File.open(path, 'w') { |file| file.write(str) }
            end
        end
    end
    
    def self.validate(config)
        true
    end

end

=begin
CONFIG_FILE_JSON = 'db/settings.json'
CONFIG_FILE_YAML = 'db/settings.yaml'

conf = SLConfig.new
json_bench = Benchmark.measure {conf.load_config(CONFIG_FILE_JSON)}
yaml_bench = Benchmark.measure {conf.load_config(CONFIG_FILE_YAML, :YAML)}

puts "JSON bench load: #{ json_bench.real }"
puts "YAML bench load: #{ yaml_bench.real }"

puts conf.config
puts JSON.pretty_generate(conf.config)
conf.restore_default! #("nmrdata")
puts JSON.pretty_generate(conf.config)
json_bench = Benchmark.measure { conf.save_config(CONFIG_FILE_JSON)}
yaml_bench = Benchmark.measure { conf.save_config(CONFIG_FILE_YAML, :YAML)}
puts "JSON bench save: #{ json_bench.real }"
puts "YAML bench save: #{ yaml_bench.real }"
=end
