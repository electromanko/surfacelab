module Surfacelab
    
    BBIF = {
        :GPIO => {
                    :DSL_RESET => { :bbpin => :P8_7 , :bbmode => :OUT, :active => :high },
                    :DSL_MASTER => { :bbpin => :P8_8 , :bbmode => :OUT, :active => :low },
                    :DSL_LINKUP => {:bbpin => :P8_11, :bbmode => :IN, :bbpullmode => :PULLDOWN, :active => :high},
        
                    :DSL_NRDY => {:bbpin => :P9_42, :bbmode => :IN, :bbpullmode => :PULLUP, :active => :low},
                    :DSL_IRQ => {:bbpin => :P8_12, :bbmode => :IN, :bbpullmode => :PULLUP, :active => :low},
                    
                    :DSL_CUART_CTS => {:bbpin => :P8_31, :bbmode => :IN, :bbpullmode => :PULLDOWN, :active => :low},
                    :DSL_CUART_RTS => {:bbpin => :P8_32, :bbmode => :OUT, :active => :high},
        
                    :MCU_RESET => { :bbpin => :P8_39, :bbmode => :OUT, :active => :high },
                    :MCU_BOOT => { :bbpin => :P8_39, :bbmode => :OUT, :active => :high },
        
                    :LED_0 => { :bbpin => :P8_41 , :bbmode => :OUT, :active => :high },
                    :LED_1 => { :bbpin => :P8_42 , :bbmode => :OUT, :active => :high },
                    :LED_2 => { :bbpin => :P8_43 , :bbmode => :OUT, :active => :high },
                    :LED_3 => { :bbpin => :P8_44 , :bbmode => :OUT, :active => :high },
                    :LED_4 => { :bbpin => :P8_45 , :bbmode => :OUT, :active => :high },
                    :LED_5 => { :bbpin => :P8_46 , :bbmode => :OUT, :active => :high },
                    
                    :USR0 => { :bbpin => :USR0 , :bbmode => :OUT, :active => :high },
                    :USR1 => { :bbpin => :USR1 , :bbmode => :OUT, :active => :high },
                    :USR2 => { :bbpin => :USR2 , :bbmode => :OUT, :active => :high },
                    :USR3 => { :bbpin => :USR3 , :bbmode => :OUT, :active => :high },
        },
        :SPI => {
                    :DSL_SPI_DATA => {:bbspi => :SPI1, :bbspeed => 100000, :bbbpw => 16 }
        },
        :UART =>{
                    :MCU_UART_DEPTH_BOOT => {:bbuart => :UART4, :bbspeed => 19200},
                    :MCU_UART_DEPTH_EXTERN => {:bbuart => :UART1, :bbspeed => 19200},
                    :MCU_UART_TELEMETRY => {:bbuart => :UART2, :bbspeed => 19200},
                    :MCU_UART_DSL_CONFIG => {:bbuart => :UART5, :bbspeed => 19200},
        }
    }.freeze
    
    class << self
        def bbinit()
            devhash = {
                :GPIO => {},
                :SPI => {},
                :UART => {}
            }
            BBIF[:GPIO].each{ |key,value|
                devhash[:GPIO][key] = GPIOPin.new(value[:bbpin],value[:bbmode])
            }
            BBIF[:SPI].each{ |key,value|
                devhash[:SPI][key] = SPIDevice.new(value[:bbspi])
                devhash[:SPI][key].set_speed(value[:bbspeed]) if value[:bbspeed]
                devhash[:SPI][key].set_bpw(value[:bbbpw]) if value[:bpw]
            }
            BBIF[:UART].each{ |key,value|
                devhash[:UART][key] = UARTDevice.new(value[:bbuart])
                devhash[:UART][key].set_speed(value[:bbspeed]) if value[:bbspeed]
            }
            devhash
        end
        
        def bbdeinit(devhash)
            devhash[:GPIO].each{ |key, value|
                value.disable_gpio_pin
                devhash[:GPIO].delete(key)
            }
            devhash[:SPI].each{ |key, value|
                value.disable
                devhash[:SPI].delete(key)
            }
            devhash[:UART].each{ |key, value|
                value.disable
                devhash[:UART].delete(key)
            }
        end
    end
    
    class SurfacelabDevice
        
        def initialize()
            @devhash = Surfacelab::bbinit()
            #Surfacelab::bbdeinit (@devhash)
            #puts @devhash
        end
        def devhash
            @devhash
        end
    end
    
end