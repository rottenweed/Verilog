#! /usr/bin/ruby -w

# Verilog symbol
class Verilog_symbol
    attr_reader(:name, :type);
    attr_accessor(:port_list);

    def initialize(name, type)
        @name = name;
        @type = type;
        @port_list = [];
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
module_inst_in = false; # <module_type> <module_name> (...);
# symbol type status
state_catch_module = 0; # module xxx
state_catch_reg = 0;    # state in reg define line
state_catch_wire = 0;   # state in wire define line
state_module_inst = 0;  # state in module instance
# the size of vector, [vector_index_max : vector_index_min]
vector_index_max = 0;
vector_index_min = 0;

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
                module_inst_in = false;
                state_catch_reg = 0;
                state_catch_wire = 0;
                state_module_inst = 0;
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
                state_catch_module = 0;
            when(:endmodule)
                module_in = false;
                state_catch_module = 0;
                line_end = true;
            when(:reg)
                reg_in = true;
                state_catch_reg = 0;
            when(:wire)
                wire_in = true;
            else
                if(line_pre_command)
                    ;   # not process ` line
                elsif(module_in && (state_catch_module == 0))
                    symbol_table << Verilog_symbol.new(token, :module);
                    state_catch_module = 1;
                elsif(reg_in)
                    case(state_catch_reg)
                        when 0
                            if(token == "[")
                                state_catch_reg = 1;
                            else
                                symbol_table << Verilog_symbol.new(token, :reg);
                                state_catch_reg = 6;
                            end
                        when 1
                            vector_index_max = token.to_i;
                            state_catch_reg = 2;
                        when 2 # :
                            state_catch_reg = 3;
                        when 3
                            vector_index_min = token.to_i;
                            state_catch_reg = 4;
                        when 4 # ]
                            state_catch_reg = 5;
                        when 5
                            vector_index_min.upto(vector_index_max) {|i|
                                symbol_table << Verilog_symbol.new(token + "_" + i.to_s, :wire);
                            }
                            state_catch_reg = 6;
                        when 6
                            if(token == ",")
                                state_catch_reg = 0;
                            end
                    end
                elsif(wire_in)
                    case(state_catch_wire)
                        when 0
                            if(token == "[")
                                state_catch_wire = 1;
                            else
                                symbol_table << Verilog_symbol.new(token, :wire);
                                state_catch_wire = 6;
                            end
                        when 1
                            vector_index_max = token.to_i;
                            state_catch_wire = 2;
                        when 2 # :
                            state_catch_wire = 3;
                        when 3
                            vector_index_min = token.to_i;
                            state_catch_wire = 4;
                        when 4 # ]
                            state_catch_wire = 5;
                        when 5
                            vector_index_min.upto(vector_index_max) {|i|
                                symbol_table << Verilog_symbol.new(token + "_" + i.to_s, :wire);
                            }
                            state_catch_wire = 6;
                        when 6
                            if(token == ",")
                                state_catch_wire = 0;
                            end
                    end
                elsif(module_inst_in)
                    case(state_module_inst)
                        when 1
                            symbol_table << Verilog_symbol.new(token, :module_inst);
                            state_module_inst = 2;
                        when 2 # "("
                            state_module_inst = 3;
                        when 3 # "."
                            state_module_inst = 4;
                        when 4 # <port name>
                            symbol_table[-1].port_list << token;
                            state_module_inst = 5;
                        when 5 # "("
                            state_module_inst = 6;
                        when 6 # connection
                            state_module_inst = 7;
                        when 7 # ")"
                            state_module_inst = 8;
                        when 8
                            if(token == ",")
                                state_module_inst = 3;
                            elsif(token == ")")
                                state_module_inst = 0;
                            end
                    end
                elsif(token =~ /[_a-zA-Z]\w*/) # module instance start
                    module_inst_in = true;
                    state_module_inst = 1;
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
    if(item.port_list.size > 0)
        Log.print("\t#{item.port_list}\n");
    end
}
list_file.close;

