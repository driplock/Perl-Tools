#!/usr/bin/perl -w

use strict;
use Net::SIP;
use threads;
use threads::shared;

my $stop: shared;

 &createregister();
 print "To stop process please input 'q'\n";
 while($stop=<STDIN>){
	chop $stop;
	if ($stop eq 'q'){
          qx/rm -rf pcmu8000-*/;
          sleep 1; 
          exit 0;
 	} 
 }


########################################################################################
####Creates Hash of From's and Audio file ref###########################################
########################################################################################

sub createfrom{
 
 my $pcmufile="pcmu8000";
 my $start_from=$ARGV[0];
 my $number_of_calls=$ARGV[1];
 my %caller;
 my $counter=0; 
 while($counter != $number_of_calls){
    $caller{$start_from}=$pcmufile."-".$start_from;
    qx/cp $pcmufile $pcmufile-$start_from/;
    $start_from++;
    $counter++;    
 }
 return %caller; 
 
} 

########################################################################################
####Create Array's of To's #############################################################
########################################################################################

sub createto{

 my $start_to=$ARGV[2];
 my @to;
 my $number_of_calls=$ARGV[1];
 my $counter=0;
 while($counter != $number_of_calls){
   $to[$counter]=$start_to;
   $counter++;
   $start_to++;
 }
 return @to;
}


########################################################################################
#####Registrations to IP-PBX and Invite to extension####################################
########################################################################################


sub createregister{
 my @callto=createto();
 my %callfrom=createfrom();
 my $counter=0;
	while(my ($from,$audiofile)= each(%callfrom)){
        my $thr=threads->create(sub {	
		my $user=Net::SIP::Simple->new( registrar => '10.3.1.150',
		      			        from => 'sip:'.$from.'@10.3.3.122:5060',
					        auth => [$from, 'abcd*1234'],
                                                );
	
	        $user->register(expires=>7200);
		$user->invite('sip:'.$callto[$counter].'@10.3.1.150',
			       init_media => $user->rtp( 'media_send_recv', $audiofile, -1 )	
			      );
		$user->loop(\$stop);
		
           
	  })->detach();
	$counter++;
        }
}



	      
