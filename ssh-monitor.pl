#!/usr/bin/perl -w 

use strict;
use Net::SSH::Expect;
use Nmap::Scanner;
use Net::Ping;


my $output;
my $outputfile=GetDate();
my $error=GetDate() . "\.error";
my $i=0;
my $check;
my $mode=$ARGV[0] || 1;
#############List of commands to send to the host....and Array of Hashes###############################
###NOTE: "waittime" is the wait time until the whole output is displayed before we grab the output#####
### So if the command that was sent takes a little while before the output comes up..its better set####
############ the wait time higher...wait time is in seconds............################################
my @commands= ( 
		{command => "uname -a", 	waittime => "1"},
		{command => "df -h", 		waittime => "2"},
		{command => "vmstat",		waittime => "1"},
		{command => "top -b",     	waittime => "2"}
		);
################################################################	
################Host, User and Password#########################
################################################################
my $user="user";
my $password="password";
my $host="127.0.0.1";

################################################################
if ($mode eq "-n"){
	my $nmapcheck=NmapFinder();
	if ($nmapcheck == 1){
	
		my $getpingresult=Ping();

		if ($getpingresult == 1){
			my $scanresult = NmapScan();
			
				if($scanresult =~/open/ig){
					&SshLogin;	
				}
				else{
					open ERR, ">$error" or die "cant open for writing";
					print ERR "Port 22 is closed";
					close ERR;
					exit 0;
				}
		}
		else{
			print "Ping Failed...\n Trying to ping ". $host. " the second time \n";
			$getpingresult=Ping();
			
			if($getpingresult == 1){
				my $scanresult = NmapScan();
	        	 
			       if($scanresult =~/open/ig){
	        	                &SshLogin;
	        	        }
	        	        else{
	        	                open ERR, ">$error" or die "cant open for writing";
	        	                print ERR "Port 22 is closed";
	        	                close ERR;
	        	                exit 0;
	        	        }
	
			}		
		
			else{
				open ERR, ">$error" or die "cant open for writing";
				print ERR "Ping Failed the second time...\n Server might be down";
				close ERR;
				exit 0;
			}
	
		}
	}
	else{
		open ERR, ">$error" or die "cant open for writing";
		print ERR "Could not Find Nmap...\n1.)Nmap might not be installed.\n2.)Path may not be correct default is /usr/local/bin \n";
		print ERR "Change Line 179 of the code if the path is incorrect";
		close ERR;
		exit 0;
	}
}
elsif($mode eq 1){
	my $getpingresult=Ping();
        
	if ($getpingresult == 1){
		&SshLogin;
        }
	else{
		print "Ping failed...\nTrying to ping ".$host." the second time\n";
		$getpingresult=Ping();                
		if($getpingresult == 1){
		        &SshLogin;
                }
                else{
                	open ERR, ">$error" or die "cant open for writing";
                	print ERR "Ping Failed the second time...\nServer might be down";
                	close ERR;
                	exit 0;
                }
	}
}
else{
	open ERR, ">$error" or die "cannot open for writing";
	print ERR "Option does not exist \n";
	print ERR "Usage: $0 [options:-n] \n";
	print ERR "$0 -n <===to enable Nmap \n";
	print ERR "$0 	<===Nmap disabled\n";
	close ERR;
	exit 0;
}	
	
#########################Sub routines############################

sub SshLogin{
	open OUT, ">$outputfile" or die "cant open for writing";
        my $ssh= Net::SSH::Expect->new( host => $host,
                                       password=> $password,
                                       user => $user,
			               raw_pty => 1,
				     #  timeout => 5,
				       exp_debug => 1,
				       log_file => $outputfile,
				       );
	$ssh->run_ssh();
        $ssh->login();
        $ssh->send("su");
        if ($ssh->peek(1)=~/Password\:/ig){ 						######check if Password prompt comes up###
                $ssh->send($password);
                }
	my $commandline=$ssh->eat($ssh->peek(1));
	$commandline=~ s/Password\://g;							#####remove string "Password:"      ######
	$commandline=~ s/su|sudo su//g;							#####remove string "su" or "sudo su"#######
	$commandline=~ s/^\s+|\s+$//g; 							#####remove trailing and leading whitespaces
	for $i (0 .. $#commands)
                {
               	        $ssh->send($commands[$i]->{'command'});
			$output=$ssh->eat($ssh->peek($commands[$i]->{'waittime'}));
			$output=~ tr/\cM//d;						#####To remove ^M on every line#####
			$output=~ s/Password\://g;
			$output=~ s/$commandline//g;
			print OUT $output . "\n\n";
                                
                }
        close OUT;
        $ssh->close();
}


#####Get current date##############	
sub GetDate{
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =localtime(time);
	my $date=sprintf ("%0.2d", $mday);
	$date.=sprintf("%0.2d",$mon+1);
	$date.=($year+1900);
	$date.=".report";
	return $date;
}

#####To check if the host is up##########
sub Ping{
	my $i=0;
	my $result;	
	my $ping=Net::Ping->new("icmp");
	while($i != 3){
		sleep 1;
		if($ping->ping($host)){
			$result=1;
		}
		else{
			$result=0;
		}
	$i++;
	}
	$ping->close();
	return $result;
}

#####to check if port 22 is open############
sub NmapScan{
	my $nmap="closed";
	my $scan= Nmap::Scanner->new();
	$scan->nmap_location('/usr/local/bin/nmap');
	$scan->add_target($host);
	$scan->add_scan_port('22');
	$scan->tcp_syn_scan();
	my $result=$scan->scan();
	my $hosts=$result->get_host_list();
	
		while(my $host= $hosts->get_next()){
			my $ports = $host->get_port_list();
			while(my $port =$ports->get_next()){
				$nmap=$port->state();
				}
		}
	return $nmap;		
}	
	

#####To check if Nmap is present under /usr/local/bin######
##### the path can be changed according to where nmap is###

sub NmapFinder{
	my $dir="/usr/local/bin";
	opendir DIR, $dir or die "could not change directory";
	my $filecheck=0;
	my $file;
	while($file=readdir DIR){
	        if($file=~/nmap/ig){
	                $filecheck=1;
	        }
	}
	closedir DIR;
	return $filecheck;
	}


