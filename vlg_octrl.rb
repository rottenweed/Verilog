#! /usr/bin/ruby -w
# generate I/O control

# constants
TAB = " " * 4;

# Generate the Verilog codes for a io port.
def vlg_io_gen(io_name, io_ctrl)
    VLG << TAB;
    VLG << "assign #{io_name}";
end

# Check CSV file: description
raise "Need an argument!\nUsage: #{$0} <filename.csv>" if(ARGV.size != 1);
filename = ARGV[0];
# Filename is the same as module name.
raise "Not csv file!" unless(/^(?<module_name>\w+)\.csv$/i =~ filename);
raise "File #{filename} open failed!" unless(CSV = File.open(filename, "r"));
# Create Verilog file.
VLG = File.open(module_name + ".v", "w");

# Read CSV lines, then generate the signal table.
lineCnt = 0;
io_name = "";
io_ctrl = [];
CSV.each {|line|
    lineCnt += 1;
    next if(line[0] == ";")  # ";" starts a comment line.
    line.chomp!;
    item = line.split(/\s*,\s*/);
    if(item[0] != "")
        # io port name
        if(io_name == "")   # the first output
            io_name = item[0];
        else    # create the verilog code for the last io
            vlg_io_gen(io_name, io_ctrl);
            io_name = item[0];
            io_ctrl = [];
        end
    else
        # Add a control item for the current port.
        io_ctrl_item = [];
        io_ctrl_item[0] = item[1].to_i; # priority
        io_ctrl_item[1] = item[2];      # selection
        io_ctrl_item[2] = item[3];      # signal
        # Insert the items according to the priority.
        if(io_ctrl.size > 0)
            (io_ctrl.size - 1).downto(0) {|i|
                if(io_ctrl[i][0] == io_ctrl_item[0])
                    raise "Equal priority in line #{lineCnt}";
                elsif(io_ctrl[i][0] < io_ctrl_item[0])
                    io_ctrl.insert(i + 1, io_ctrl_item);
                    break;
                elsif(i == 0)
                    io_ctrl.insert(0, io_ctrl_item);
                end
            }
        else
            io_ctrl << io_ctrl_item;
        end
    end
}

CSV.close;
VLG << "\n";
VLG.close;
