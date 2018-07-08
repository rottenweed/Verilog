#! /usr/bin/ruby -w

print("Test the 1st scan for Verilog netlist.\n");
exit(1) unless(list_file = File.open(ARGV[0], "r"));

Verilog_ptn = /\/\/|\/\*|\*\/|[\.\(\)\[\]\\\/\*\#`'{}:=~,;$]|\w+/;

token = [];
line_no = 0;
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
        print(token, "\n");
    end
    token = [];
}
print("Total line count = #{line_no}\n");

list_file.close;

