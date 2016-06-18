#!/usr/bin/perl -w

use strict;
use Net::SIP;
use threads;
use threads::shared;
my $stop:shared;

&createregister();
print "To stop process please input 'q'\n";
while($stop=<STDIN>){
   chop $stop;
   if($stop eq 'q'){
        sleep 2;
        exit();
   }          
}


################################################################################
#########Create Arrays of From's################################################
################################################################################

sub createfrom{

 my $start_from=$ARGV[0];
 my @from;
 my $number_of_calls=$ARGV[1];
 my $counter=0;
 while($counter != $number_of_calls){
   $from[$counter]=$start_from;
   $counter++;
   $start_from++;
 }
 return @from;
}
#################################################################################
#####Create Register and Listen Child Process####################################
#################################################################################


sub createregister{
 my $counter=0;
 my @from=createfrom();
 while($counter != $ARGV[1]){
    threads->create(sub {	
    my $user=Net::SIP::Simple->new( registrar => '10.3.3.128',
	      	      		       from => 'sip:'.$from[$counter].'@10.3.3.127:5060',
				       auth => [$from[$counter], '123qwe321']);


			$user->register;
			$user->listen( init_media=> $user->rtp('send_recv','test.pcmu8000'));
			$user->loop(\$stop);
                                               
     })->detach();
    $counter++;
      
 }
}



	      
