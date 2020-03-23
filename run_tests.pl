print "running make...\n";
$ret_val = system "make";
if ($ret_val) {
    exit $ret_val;
}

@files = split /\n/, `ls tb | grep "\.exe"`;
print "running tests...\n";
for (@files) {
    print $_ . ': ';
    $output = `tb/$_` ;

    if (length $output > 0) {
         print $output;
    }
    else {
        print "\n";
    }
}
