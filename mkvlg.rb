#! /usr/bin/ruby

# constants
TAB = " " * 4;

# Check CSV file: description
raise "Need an argument!\nUsage: #{$0} <filename>" if(ARGV.size != 1);
filename = ARGV[0];
# Filename is the same as module name.
raise "Not csv file!" unless(/^(?<module_name>\w+)\.csv$/i =~ filename);
raise "File #{filename} open failed!" unless(CSV = File.open(filename, "r"));

# Create Verilog file.
VLG = File.open(module_name + ".v", "w");

# Read the csv and generate IO signal table.
ioTable = [];
lineCnt = 0;
CSV.each {|line|
    lineCnt += 1;
    next if(line[0] == ";")  # ";" starts a comment line.
    line.chomp!;
    item = line.split(/\s*,\s*/);
    if(item.size < 3)
        print("line #{lineCnt}: Not a valid line.\n");
    else
        # process the IO signals
        if(item[2] == "i")
            item[2] = "input";
        elsif(item[2] == "o")
            item[2] = "output";
        elsif(item[2] == "io")
            item[2] = "inout";
        else
            raise "Error I/O type @line #{lineCnt}";
        end
        ioTable << item;
    end
}

# Write the Verilog module description.
VLG << "module #{module_name} (\n";
lineCnt = 0;
ioTable.each {|item|
    VLG << "#{TAB}#{item[0]}";
    VLG << "," if(lineCnt < ioTable.size - 1);
    VLG << "\n";
    lineCnt += 1;
}
VLG << "#{TAB});\n\n";
# Write the IO table of the module.
ioTable.each {|item|
    io_def = "#{TAB}#{item[2]} ";
    io_def += "[#{item[1]}:0]" if(item[1].to_i > 1);
    VLG << io_def;
    VLG << " " * (24 - io_def.length);
    VLG << "#{item[0]};\n";
}

VLG << "\nendmodule\n\n";

CSV.close;
VLG.close;
