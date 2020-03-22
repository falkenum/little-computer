
print "running make...\n";
system "cd tb && make";
@files = split /\n/, `ls tb | grep "\.exe"`;

print "running tests...\n";
for (@files) {
    $output = `tb/$_` ;

    if (length $output > 0) {
        print $_ . ': ' . $output;
    }
}
