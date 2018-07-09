#! /usr/bin/ruby -w

print("Test the 1st+2nd scan for Verilog netlist.\n");
exit(1) unless(list_file = File.open(ARGV[0], "r"));
Log = File.open("list.log", "w");

# Verilog supporting characters
Verilog_ptn = /\/\/|\/\*|\*\/|[\.\(\)\[\]\\\/\*\#`'{}:=~,;$]|\w+/;
# Verilog key words
Verilog_key = {
    "`" => :pre,
    "module" => :module,
    "endmodule" => :endmodule,
    "reg" => :reg,
    "wire" => :wire
    };

token = [];
line_no = 0;
module_in = false;

# scan 1: delete comments, generate tokens
in_comment = false;
list_file.each_line {|line|
    line_no += 1;
    while(line =~ Verilog_ptn)
        token << $& if(!in_comment);
        line = $';
        case($&)
            when("\/\/")
                # meet "//", line comment
                # delete "//" and all characters after it
                token.delete_at(-1);
                line = "";
            when("\/\*")
                # start comment
                # delete "/*"
                token.delete_at(-1);
                in_comment = true;
            when("\*\/")
                # end comment
                # delete "*/"
                token.delete_at(-1);
                in_comment = false;
        end
    end
    if(token.size > 0)
        Log.print(token, "\n");
    end

    # scan 2: scan the tokens in a line
    line_pre_command = false;
    token.each {|word|
        case(Verilog_key[word])
            when(:pre)
                line_pre_command = true;  # no process `command
            when(:module)
                module_in = true;
            when(:endmodule)
                module_in = false;
            when(nil)
                if(line_pre_command)
                    # this token is not process
                    word = "";
                else
                    print(word, " ");
                end
        end
    }
    token = [];
}
print("Total line count = #{line_no}\n");

list_file.close;

