
if ($ARGV[0] eq "clean") {
    print "cleaning...\n";
    system "cd tb && make clean";
}

print "running make...\n";
$ret_val = system "cd tb && make";
if ($ret_val) {
    exit ret_val;
}

@files = split /\n/, `ls tb | grep "\.exe"`;
print "running tests...\n";
for (@files) {
    $output = `tb/$_` ;

    if (length $output > 0) {
        print $_ . ': ' . $output;
    }
}
