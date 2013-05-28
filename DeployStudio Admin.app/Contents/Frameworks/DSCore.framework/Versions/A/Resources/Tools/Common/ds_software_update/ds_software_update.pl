#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

$ENV{COMMAND_LINE_INSTALL} = 1;

print basename($0) . " - v1.6 (" . localtime(time) . ")\n";

# Wait for network services to be initialized
print "Checking for the default route to be active...\n";
my $ATTEMPTS = 0;
my $MAX_ATTEMPTS = 18;
while (system("netstat -rn -f inet | grep -q default") != 0) {
    if ($ATTEMPTS <= $MAX_ATTEMPTS) {
        print "Waiting for the default route to be active...\n";
        sleep 10;
        $ATTEMPTS++;
    } else {
        print "Network not configured, software update failed ($MAX_ATTEMPTS attempts), will retry at next boot!\n";
        exit 1;
    }
}

# Checking SUS reachability...
print "Checking server reachability...\n";
my $SUS_HOST_NAME = "__SUS_HOST_NAME__";
my $RESET_WHEN_DONE = "__RESET_WHEN_DONE__";
if (length($SUS_HOST_NAME) > 0) {
    if (system("ping -c 1 -n -t 10 \"$SUS_HOST_NAME\" &>/dev/null") != 0) {
        print "The Software Update server '$SUS_HOST_NAME' is not reachable, skipping...\n";
   
        # Reset local SUS url if required
        if (length($RESET_WHEN_DONE) > 0) {
            system("/usr/bin/srm -mf /Library/Preferences/com.apple.SoftwareUpdate.plist");
        }
        
        # Self removal
        system("/usr/bin/srm -mf \"$0\"");

        exit 200;
    }
}

# Check if updates are available
print "Checking if updates are available...\n";
my @NEW_UPDATES = `/usr/sbin/softwareupdate -l 2>/dev/null | grep "^  *\* " | sed s/"^ *\\* *"// | awk -F- '{ print \$1 }'`;
if (@NEW_UPDATES > 0) {
    while (@NEW_UPDATES > 0) {
        # Remove trailing newlines
        chomp(@NEW_UPDATES);

        # Run Apple Software Update client from the CLI
        print "Installing all updates available (" . @NEW_UPDATES . ")...\n";

        system("/usr/sbin/softwareupdate -i -a");
    
        # Disable installed updates temporarily
        print "Temporarily disabling installed updates...\n";
        foreach (@NEW_UPDATES) {
            system("/usr/sbin/softwareupdate --ignore \"$_\"");
        }
        
        # Check if updates are available
        print "Checking if updates are available...\n";
        @NEW_UPDATES = `/usr/sbin/softwareupdate -l 2>/dev/null | grep "^  *\* " | sed s/"^ *\\* *"// | awk -F- '{ print \$1 }'`;
    }
} else {
    print "No new software available...\n";

    # Reset previously ignored updates
    system("/usr/sbin/softwareupdate --reset-ignored");

    # Reset local SUS url if required
    if (length($RESET_WHEN_DONE) > 0) {
        system("/usr/bin/srm -mf /Library/Preferences/com.apple.SoftwareUpdate.plist");
    }

    # Self removal
    system("/usr/bin/srm -mf \"$0\"");
    
    exit 200;
}

exit 0;
