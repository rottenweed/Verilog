#! /usr/bin/ruby -w

# Verilog symbol
class Verilog_symbol
    attr_accessor(:name, :type);

    def initialize(name, type)
        @name = name;
        @type = type;
    end
end

print("Test the 1st+2nd scan for Verilog netlist.\n");
exit(1) unless(list_file = File.open(ARGV[0], "r"));
Log = File.open("list.log", "w");

# Verilog supporting characters
Verilog_ptn = /\/\/|\/\*|\*\/|[\n\.\(\)\[\]\\\/\*\#`'{}:=~,;$]|\w+/;
# Verilog key words
Verilog_key = {
    "`" => :pre,
    "module" => :module,
    "endmodule" => :endmodule,
    "reg" => :reg,
    "wire" => :wire,
    "\n" => :key_r,
    ";" => :semicolon
    };

token = "";             # current Verilog token
line_stream = [];       # a real Verilog line
symbol_table = [];      # user defined symbol
line_no = 0;
line_end = false;       # current Verilog line is end, normally by ;
module_in = false;      # module ... endmodule
wire_in = false;        # wire ... ;
reg_in = false;         # reg ... ;
# symbol type status
catch_module_state = 0; # module xxx
catch_reg_state = 0;    # state in reg define line
catch_wire_state = 0;   # state in wire define line

in_comment = false;
list_file.each_line {|line|
    line_no += 1;
    line_pre_command = false;
    while(line =~ Verilog_ptn)
    # scan 1: delete comments, generate tokens
        token = "";
        line = $';
        case($&)
            when("\/\/")
                # meet "//", line comment
                # delete "//" and all characters after it
                line = "";
            when("\/\*")
                # start comment
                # delete "/*"
                in_comment = true;
            when("\*\/")
                # end comment
                # delete "*/"
                in_comment = false;
            else
                token = $& if(!in_comment);
                if(token != "")
                    line_stream << token;
                end
        end

        # scan 2: scan and translate the tokens
        case(Verilog_key[token])
            when(:semicolon)
                line_end = true;    # end the Verilog line
                reg_in = false;
                wire_in = false;
                catch_reg_state = 0;
                line_stream.delete_at(-1);
            when(:pre)
                line_pre_command = true;
            when(:key_r)
                # end the Verilog `command line
                if(line_pre_command)
                    line_pre_command = false;
                    line_end = true;
                end
                line_stream.delete_at(-1);
            when(:module)
                module_in = true;
                catch_module_state = 0;
            when(:endmodule)
                module_in = false;
                catch_module_state = 0;
                line_end = true;
            when(:reg)
                reg_in = true;
                catch_reg_state = 0;
            when(:wire)
                wire_in = true;
            else
                if(module_in && (catch_module_state == 0))
                    symbol_table << Verilog_symbol.new(token, :module);
                    catch_module_state = 1;
                elsif(reg_in)
                    case(catch_reg_state)
                        when 0
                            if(token != "[")
                                symbol_table << Verilog_symbol.new(token, :reg);
                                catch_reg_state = 6;
                            end
                    end
                elsif(wire_in)
                    case(catch_wire_state)
                        when 0
                            if(token != "[")
                                symbol_table << Verilog_symbol.new(token, :wire);
                                catch_wire_state = 6;
                            else
                                catch_wire_state = 1;
                            end
                    end
                end
        end
    end

    # output the tokens to log file
    if(line_end == true)
        line_stream.each {|word|
            Log.print(word, " ");
        }
        Log.print("\n");
        line_stream = [];
    end
    line_end = false;
}
print("Total line count = #{line_no}\n");

Log.print("\nVerilog item list: \n");
symbol_table.each {|item|
    Log.print(item.name, " : ", item.type, "\n");
}
list_file.close;

