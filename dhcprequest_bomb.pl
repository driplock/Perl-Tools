#!/usr/bin/perl 

use warnings;
use strict;
use threads;
use threads::shared;
use Net::DHCP::Packet;
use Net::DHCP::Constants;
use Net::RawIP;
use Time::HiRes 'time';

my $ctr : shared;
$ctr=$ARGV[0];

if(@ARGV!=1)
{
	print "Usage:$0 [Number of Request] \n";
	exit;
}

my @mac_arr : shared;
my @ip_arr : shared;
my $start_time = time();

my $thrmac = threads->create(\&genmac);
$thrmac->join;
my $thrip = threads->create(\&genip);
$thrip->join;

##### MAC address generator #############

sub genmac
{
 my $test_mac="004d";
 my $a=0;
 my $i=0;
        while($i != $ctr)
        {
                while($a++<4)
                        {
                        $test_mac.=sprintf("%x",int rand 16);
                        $test_mac.=sprintf("%x",int rand 16);
                        }
                $mac_arr[$i]=$test_mac;
                $a=0;
                $test_mac="004d";
                $i++;

        }
return @mac_arr;
}


##### REQUEST IP GENERATOR ############

sub genip
{
	my $loopcounter=0;
	my $ip_req=172.17;
	my $xip=0;
	my $yip=1;
	my @ips;
	while($loopcounter != $ctr)
	{
	        $ip_req.= "." . $xip;
	        $ip_req.= "." . $yip;
	        $ips[$loopcounter]=$ip_req;
	        $yip++;
	        if ($yip == 255)
        	         {
                	  $xip++;
	                  $yip=0;
	                }
        	         if ($xip == 255)
                	        {
                        	print "IP Limit Exceeded\n";
	                        exit();
        	                }
                	$loopcounter++;
	        $ip_req=172.17;
	}
@ip_arr=@ips;
return @ip_arr;
}

############ THREADS ###################

my $thrreq = threads->create(\&sub1, @mac_arr, @ip_arr);
$thrreq->join;
 	
	sub sub1 
	{
		my $count = 0;	
		for (1..$ctr) 
		{ 	

######### DHCP request packet ###########

			my $p= Net::DHCP::Packet->new( op => '1',
                        			       hlen => '6',
			                               htype => '1',
                        			       hops => '0');
			my $id=int(rand(0xFFFFFFFF));
			my $mac=$mac_arr[$count];
			my $ip=$ip_arr[$count];		
			$p->chaddr($mac);
			$p->xid($id);
			$p->isDhcp();
			$p->addOptionValue(DHO_DHCP_MESSAGE_TYPE(), 3);
			$p->addOptionValue(DHO_DHCP_SERVER_IDENTIFIER(), "172.17.0.34");
			$p->addOptionValue(DHO_DHCP_REQUESTED_ADDRESS(), $ip);
			my $packet= $p->serialize();

######### DHCP request header ############

			my $n = Net::RawIP->new({ ip => {
			                                saddr => '0.0.0.0',
                        			        daddr => '255.255.255.255',
			                                },
                        			udp => {
			                                source => 68,
                        			        dest => 67,
			                                data => $packet
                        			        }
			                        });

	
			my @macar= split //, $mac;
			my $i;
			my $macjoin;
			my $counter=0;
			        foreach $i (@macar)
			                {
			                $macjoin.=$i;
			                $counter++;
			                        if($counter%2==0)
                        			{
			                        $macjoin.=":";
                        			}
			}
			chop ($macjoin);
			$n->ethnew("bge0");
			$n->ethset( source => $macjoin , dest => 'ff:ff:ff:ff:ff:ff');
			$n->ethsend;
  			$count++;
		}
		print "\n\nTotal number of Requests: $count\n\n";
  	}


######### Caculate Time ################

&Calc_time($start_time);

sub Calc_time{

        my $start_time = shift;
        my $end_time = time();
        my $prcs_time = $end_time - $start_time;
        my @ftime=(0,0,0);
	my $msec;

        while(1){
        if($prcs_time >= 3600)
		{
                	$ftime[0] = int($prcs_time/3600); 
			$prcs_time = $prcs_time-($ftime[0]*3600);
        } elsif ($prcs_time >= 60)
		{ 
                	$ftime[1] = int($prcs_time/60);
			$prcs_time = $prcs_time-($ftime[1]*60);
        } else {
                ($ftime[2], $msec) = $prcs_time=~/(\d+)\.(\d+)$/; while($msec =~/(\d{3})/g){ push @ftime, $1; }
                print "Time --> $ftime[0]:$ftime[1]:$ftime[2].$ftime[3].$ftime[4]\n"; last; }

                #$ftime[2] = $prcs_time; printf "$ftime[0]:$ftime[1]:"."%.12f\n", $ftime[2]; last; }
        }
}

