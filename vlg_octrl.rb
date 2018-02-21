#! /usr/bin/ruby -w
# generate I/O control

# constants
TAB = " " * 4;

# Generate the Verilog codes for a io port.
# io_name: output port name.
# io_ctrl: items of output control.
#   [0]: priority
#   [1]: output enable control
#   [2]: output signal
# The items have been sorted by decreasing priorities.
# The lowest output enable control is not used in out selection.
# str: output codes
def vlg_io_gen(io_name, io_ctrl, str)
    str << TAB;
    str << "assign #{io_name} = ";
    last_item_no = io_ctrl.size - 1;
    0.upto(last_item_no) {|i|
        if(i == 0)
            if(i == last_item_no)
                str << "#{io_ctrl[i][2]};\n";
            else
                str << "#{io_ctrl[i][1]} ? #{io_ctrl[i][2]} :\n";
            end
        elsif(i != last_item_no)
            str << TAB * 3;
            str << "#{io_ctrl[i][1]} ? #{io_ctrl[i][2]} :\n";
        else
            str << TAB * 3;
            str << "#{io_ctrl[i][2]};\n";
        end
    }
end

# Generate the output enable control codes.
def vlg_oen_gen(io_name, io_ctrl, str)
    str << TAB;
    str << "assign #{io_name}_oen =";
    last_item_no = io_ctrl.size - 1;
    0.upto(last_item_no) {|i|
        if(i != last_item_no)
            str << " #{io_ctrl[i][1]} |";
        else
            str << " #{io_ctrl[i][1]};\n";
        end
    }
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
str_o = "";     # output signal codes
str_oen = "";   # output enable control codes
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
            vlg_io_gen(io_name, io_ctrl, str_o);
            vlg_oen_gen(io_name, io_ctrl, str_oen);
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
if(io_name != "")
    vlg_io_gen(io_name, io_ctrl, str_o);
    vlg_oen_gen(io_name, io_ctrl, str_oen);
end

CSV.close;
VLG << str_o;
VLG << "\n";
VLG << str_oen;
VLG << "\n";
VLG.close;
