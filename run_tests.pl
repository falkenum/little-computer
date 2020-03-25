print "running make...\n";
$ret_val = system "make";
if ($ret_val) {
    exit $ret_val;
}

@files = split /\n/, `ls tb | grep "\.exe"`;
print "running tests...\n";
for (@files) {
    print $_ . ': ';
    system("tb/$_");
    print '\n';
}
