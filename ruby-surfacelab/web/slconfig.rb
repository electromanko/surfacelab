require 'json'
require 'yaml'
require 'benchmark'
require "ipaddress"

class String
  def to_bool
    return true   if self == true   || self =~ (/(true|t|yes|y|1)$/i)
    return false  if self == false  || self.strip.empty? || self =~ (/(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class SLConfig
    
    @config = {}
    
    def config
        @config
    end
    def load_config(path, type=:JSON)
        if type == :JSON
            @config = JSON.parse(File.read(path))
        elsif type == :YAML
            @config = YAML.load_file(path)
        end
    end

    def save_config(path, type=:JSON)
        if type == :JSON
            File.open(path, 'w') { |file| file.write(JSON.pretty_generate(@config)) }
        elsif type == :YAML
            File.open(path, 'w') { |file| file.write(@config.to_yaml) }
        end
    end
    def update
    end
    def restore_default!(category=nil)
        if category.nil? 
            @config.each{|k, v|
               restore_default_category!(k)
            }
        else
            unless @config[category].nil?
                restore_default_category!(category)
            else 
                #raise "SomeError message ..."
            end
        end
    end
    
    def set_variable!(category, variable, value)
        var= @config[category]["items"][variable]
        unless var.nil?
            val_var = @config[category]["items"][variable]["value"]
            if check_limits?(var, value)
                #puts category+"/"+variable+":"+val_var+"|"+value
                if val_var.is_a?(TrueClass) || val_var.is_a?(FalseClass)
                    @config[category]["items"][variable]["value"]=value.to_bool
                else 
                    @config[category]["items"][variable]["value"]=value
                end
            end
        end
    end
    
    def set_categoty!(category, hvalues)
        unless @config[category].nil?
            @config[category]["items"].each {|k, v|
                set_variable!(category,k,hvalues[k])
                #puts category+"/"+k+":"+v.to_s+"|"+hvalues[k]
            }
        end
    end
    
    def check_limits?(variable, value)
        unless variable["limits"].nil?
            variable["limits"].each {|k, v|
                case k
                    when "maxlength"
                        if value.is_a?(String)
                            return false if value.length > v
                        else
                            return false
                        end
                    when "max"
                        if value.is_a?(Integer) || value.is_a?(String)
                            return false if value.to_i > v
                        else 
                            return false
                        end
                    when "min"
                        if value.is_a?(Integer) || value.is_a?(String)
                            return false if value.to_i < v
                        else 
                            return false
                        end
                    when "ipaddr"
                        if value.is_a?(String)
                            return false unless IPAddress.valid? value
                        else
                            return false
                        end
                end
            }
        end
        return true
    end
    
    def self.save_network_confg(config, iface,path)
        str="auto #{iface}\nallow-hotplug #{iface}\n"
        if config['network']['items']['dhcp']['value']==true
            str+="iface #{iface} inet dhcp\n"
        else
            str+="iface #{iface} inet static\n"
            str+="\taddress #{config['network']['items']['ip']['value']}\n"
            str+="\tnetmask #{config['network']['items']['mask']['value']}\n"
            str+="\tgateway #{config['network']['items']['gw']['value']}\n"
        end
        File.open(path, 'w') { |file| file.write(str) }
    end
    
private
    def restore_default_category!(keycat)
        #puts "Restore category #{@config[keycat]["name"]}"
        @config[keycat]["items"].each{|key,val|
                    unless val["value"].nil?
                        unless val["default"].nil?
                            val["value"]=val["default"]
                        end
                    end
        }
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
