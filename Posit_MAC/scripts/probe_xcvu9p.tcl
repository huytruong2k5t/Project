set_param general.maxThreads 4
puts "TOOL_VERSION=[version -short]"
set parts [get_parts -quiet xcvu9p*]
puts "XCVU9P_PARTS=$parts"
if {[llength [get_parts -quiet xcvu9p-flgb2104-2-i]] != 1} {
    error "Requested xcvu9p-flgb2104-2-i device is not installed"
}
puts XCVU9P_PART_AVAILABLE
exit
