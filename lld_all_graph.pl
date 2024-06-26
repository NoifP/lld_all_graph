#!/usr/bin/perl
use JSON;
use Data::Dumper;

#version 2012.06.26
#added item prototype exclusion by item key
#now 42 colors available

#version 2012.06.14
#added drawtype parameter
#added calcfunction parameter
#showtriggers now defaults to true

#version 2012.06.13.1
#added showtriggers parameter 


# load a json string from a file
sub loadjson
{
	#reset
	$result = "";

	# open file
	open(FILE, "<", $_[0]);
	# read whole file
	while (<FILE>) { $result = $result.$_; }
	# close file
	close(FILE);
	
	#return
	return $result
}


# send json and get result (jsonstr):jsonstr
sub sendjson
{
	#jsonstr
	my $jsonstr = $_[0];
	
	# send json to zabbix and get result
	my $res = `curl -s -i -X POST -H $header -d '$data' $url`;
	# find start of json
	my $i = index($res, "{");
	# get json only
	my $res_out = substr($res, $i);
	
	#return
	return $res_out;	
}


# authenticate with zabbix, returns the auth token
sub authenticate
{
	# load auth json
	local $data = '{ "jsonrpc": "2.0", "method": "user.login", "params": { "user": "'.$user.'", "password": "'.$password.'" }, "id": 1, "auth": null }';
	# send json
	my $res = sendjson($data);	
	#print $data."\n\n";
	#print "res:".$res."\n\n";
	
	my $auth_out = "";
	
	# decode json
	my $dec = eval { decode_json($res) };
	# parsing error
	if ($@)
	{
		print "[ERROR] Failed parsing response from the server! Make sure Zabbix API url is correct.\n";
		print "[ERROR] Parsing error was: $@\n";
		return $auth_out;
	}
	
	# get auth key
	$auth_out = $dec->{"result"};
	
	# report errors
	if ($dec->{"error"}) {
		print "[ERROR] Authentication error: ".encode_json($dec->{"error"}).")\n";
	}

	#return
	return $auth_out;
}


# get hostgroups from zabbix (auth)
sub gethostgroups
{
	#auth
	$auth_in = $_[0];
	
	# load hostgroups json
	$data = '{ "jsonrpc": "2.0", "method": "hostgroup.get", "params": { "output": "extend", "sortfield": "name" }, "id": 1, "auth": "" }';
	# decode json
	$dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# encode back to data
	$data = encode_json($dec);
	
	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
	#return
	return $dec_out
}



# get hosts from zabbix (auth, groupid)
sub gethosts
{
	#auth
	$auth_in = $_[0];
	#groupid
	$groupid_in = $_[1];
	
	# load items json
	$data = '{ "jsonrpc": "2.0", "method": "host.get", "params": { "output": "extend", "sortfield": "name", "selectParentTemplates": "extend", "groupids": [ "" ] }, "id": 2, "auth": "" }';
	# decode json
	$dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# set groupid filter (outside filter)
	$dec->{"params"}->{"groupids"}[0] = $groupid_in;
	# encode back to data
	$data = encode_json($dec);

#	print $data."\n\n";

	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
#	print $res."\n\n";
	
	#return
	return $dec_out;
}



# get items from zabbix (auth, hostid)
sub getitems
{
	#auth
	$auth_in = $_[0];
	#hostid
	$hostid_in = $_[1];
	
	# load items json
	$data = '{ "jsonrpc": "2.0", "method": "item.get", "params": { "output": "extend", "sortfield": "name", "filter": { "hostid": "" } }, "id": 1, "auth": "" }';

	# decode json
	$dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# set hostid filter
	$dec->{"params"}->{"filter"}->{"hostid"} = $hostid_in;
	# encode back to data
	$data = encode_json($dec);

	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
#	print $res."\n\n";
	
	#return
	return $dec_out
}


# get graphs from zabbix (auth, hostid, graphname)
sub getgraphs
{
	#auth
	$auth_in = $_[0];
	#hostid
	$hostid_in = $_[1];
	#graph
	$graph_in = $_[2];
	
	# load graphs json
	$data = '{ "jsonrpc": "2.0", "method": "graph.get", "params": { "output": "extend", "sortfield": "name", "hostids": [ "" ], "filter": { "name": "" } }, "id": 3, "auth": "" }';
	# decode json
	$dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# set name filter
	$dec->{"params"}->{"filter"}->{"name"} = $graph_in;
	# set hostid filter (outside filter)
	$dec->{"params"}->{"hostids"}[0] = $hostid_in;
	# encode back to data
	$data = encode_json($dec);

#	print $data."\n\n";

	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
#	print $res."\n\n";
	
	#return
	return $dec_out;
}



# delete graph from zabbix (auth, graphid)
sub deletegraph
{
	#auth
	$auth_in = $_[0];
	#graphid
	$graphid_in = $_[1];
	
	# load graphs json
	$data = '{ "jsonrpc": "2.0", "method": "graph.delete", "params": [ "" ], "id": 4, "auth": "" }';
	# decode json
	$dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# set graphid
	$hash[0] = $graphid_in;	
	$dec->{"params"} = \@hash;
	# encode back to data
	$data = encode_json($dec);
	
#	print $data."\n\n";

	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
#	print $res."\n\n";

	print $config_indentation.$config_indentation.$config_indentation."Graph deleted."."\n";
	
	#return
	return $dec_out;
}


# search and delete existing graphs from zabbix (auth, hostid, graphname)
sub deletegraphs
{
	#auth
	$auth_in = $_[0];
	#hostid
	$hostid_in = $_[1];
	#graph
	$graph_in = $_[2];


	# get graph with name
	$graphs = getgraphs($auth_in, $hostid_in, $graph_in);
		
	# each graph in list
	# filter graphs that do not belong to our hostid
	foreach $graphi(@{$graphs->{result}}) {
		
		# get graph id
			$graphid = $graphi->{graphid};
			# get graph name
			$graph_name = $graphi->{name};
				
			print $config_indentation.$config_indentation.$config_indentation."Graph found: ".$graph_name." (".$graphid.")"."\n";
				
			# delete the graph
			deletegraph($auth_in, $graphid);
	}
}


# create graph in zabbix (auth, graphname, graphtype, mintype, maxtype, minvalue, maxvalue, showtriggers, graphitems, hostid)
sub creategraph
{
	#ymin_type = 0 -> calculated
	#ymin_type = 1 -> fixed
	#graphtype = 0 -> normal
	#graphtype = 1 -> stack

	#auth
	$auth_in = $_[0];
	#graph name
	$graph_in = $_[1];
	#graphtype, mintype, maxtype, minvalue, maxvalue
	$graphtype_in = $_[2];
	$mintype_in = $_[3];
	$maxtype_in = $_[4];		
	$minvalue_in = $_[5];
	$maxvalue_in = $_[6];
	$showtriggers_in = $_[7];
	#graphitems
	$graphitems_in = $_[8];
	#hostid
	$hostid_in = $_[9];

	# check for existing graph (there should be only one of this name)
	local $graphs = getgraphs($auth_in, $hostid_in, $graph_in);

	# load graphs json
	local $data = '{ "jsonrpc": "2.0", "method": "graph.create", "params": { "gitems": [ "" ], "name": "", "width": "900", "height": "300", "yaxismin": "0", "yaxismax": "100", 
			   "show_work_period": "1", "show_triggers": "1", "graphtype": "0", "show_legend": "1", "show_3d": "0", "percent_left": "0", "percent_right": "0", "ymin_type": "0",
			   "ymax_type": "0", "ymin_itemid": "0", "ymax_itemid": "0" }, "id": 4, "auth": "" }';

	# decode json
	local $dec = decode_json($data);
	# set auth
	$dec->{"auth"} = $auth_in;
	# set graph name
	$dec->{"params"}->{"name"} = $graph_in;
		
	# switch to update if graph exists
	local $graph_id = 0;
	if (@{$graphs->{result}} > 0) {
		$graph_id = $graphs->{result}[0]->{graphid};
	}
	# print "\ngraph to update:".$graph_id;
	# print "\n".Dumper($graphs);
	local $isupdate = 0;
	if ($graph_id > 0) {
		$isupdate = 1;
		$dec->{"method"} = "graph.update";
		$dec->{"params"}->{"graphid"} = $graph_id;
	}
		
	# set graphtype, mintype, maxtype, minvalue, maxvalue
	$dec->{"params"}->{graphtype} = $graphtype_in;
	$dec->{"params"}->{ymin_type} = $mintype_in;
	$dec->{"params"}->{ymax_type} = $maxtype_in;
	$dec->{"params"}->{yaxismin} = $minvalue_in;
	$dec->{"params"}->{yaxismax} = $maxvalue_in;
	$dec->{"params"}->{show_triggers} = $showtriggers_in;
	# set graph gitems
	$dec->{"params"}->{gitems} = $graphitems_in;
	# encode back to data
	$data = encode_json($dec);
	
	# print Dumper($dec)."\n\n";

	# send json
	$res = sendjson($data);			
	# decode json
	$dec_out = decode_json($res);	
	
	#print $res."\n\n";
	# standard result:
	# {"jsonrpc":"2.0","result":{"graphids":["828"]},"id":4}
	# error examples:
	# {"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"Graph with name \"Active Sessions auto-stack 2\" already exists in graphs or graph prototypes."},"id":4}
	# {"jsonrpc":"2.0","error":{"code":-32602,"message":"Invalid params.","data":"No permissions to referred object or it does not exist!"},"id":4}
	
	if ($dec_out->{"result"}) {
		if (!$isupdate) {
			$graph_id = $dec_out->{"result"}->{"graphids"}[0];
			print $config_indentation.$config_indentation.$config_indentation."Graph created: ".$graph_in." (".$graph_id.")\n";
		} else {
			print $config_indentation.$config_indentation.$config_indentation."Graph updated: ".$graph_in." (".$graph_id.")\n";
		}
	} else {
		print $config_indentation.$config_indentation.$config_indentation."Error occured: ".encode_json($dec_out->{"error"}).")\n";
	}
	
	#return
	return $dec_out;
}



		#########
		# modify these values accordingly
		#########
		# should the graphs be removed on each run
		# (set to 1 to enable removing graphs before creation)
		# defaults to 0 (update, don't remove); update is better because ut preserves ids
		$config_recreate_graphs = 0;
		# visual indentation
		$config_indentation = "   ";
		require './config.pl';


##########
# Rainbow
$colors[0][0] =  "1478F0";
$colors[0][1] =  "1E82FA";
$colors[0][2] =  "288CF0";
$colors[0][3] =  "3296E6";
$colors[0][4] =  "3CA0DC";
$colors[0][5] =  "46AAD2";
$colors[0][6] =  "50B4C8";
$colors[0][7] =  "5ABEBE";
$colors[0][8] =  "64C8B4";
$colors[0][9] =  "6ED2AA";
$colors[0][10] =  "78DCA0";
$colors[0][11] =  "82E696";
$colors[0][12] =  "8CF08C";
$colors[0][13] =  "96FA82";
$colors[0][14] =  "A0F078";
$colors[0][15] =  "AAE66E";
$colors[0][16] =  "B4DC64";
$colors[0][17] =  "BED25A";
$colors[0][18] =  "C8C850";
$colors[0][19] =  "D2BE46";
$colors[0][20] =  "DCB43C";
$colors[0][21] =  "E6AA32";
$colors[0][22] =  "F0A028";
$colors[0][23] =  "FA961E";
$colors[0][24] =  "F08C14";
$colors[0][25] =  "E6820A";
$colors[0][26] =  "DC7800";
$colors[0][27] =  "D26E0A";
$colors[0][28] =  "C86414";
$colors[0][29] =  "BE5A1E";
$colors[0][30] =  "B45028";
$colors[0][31] =  "AA4632";
$colors[0][32] =  "A03C3C";
$colors[0][33] =  "963246";
$colors[0][34] =  "8C2850";
$colors[0][35] =  "821E5A";
$colors[0][36] =  "781464";
$colors[0][37] =  "6E0A6E";
$colors[0][38] =  "640078";
$colors[0][39] =  "5A0A82";
$colors[0][40] =  "50148C";
$colors[0][41] =  "461E96";
$colors[0][42] =  "3C28A0";
$colors[0][43] =  "3232AA";
$colors[0][44] =  "283CB4";
$colors[0][45] =  "1E46BE";
$colors[0][46] =  "1450C8";
$colors[0][47] =  "0A5AD2";
$colors[0][48] =  "0064DC";
$colors[0][49] =  "0A6EE6";
$colors[0][50] =  "1478F0";
$colors[0][51] =  "1E82FA";
$colors[0][52] =  "288CF0";
$colors[0][53] =  "3296E6";
$colors[0][54] =  "3CA0DC";
$colors[0][55] =  "46AAD2";
$colors[0][56] =  "50B4C8";
$colors[0][57] =  "5ABEBE";
$colors[0][58] =  "64C8B4";
$colors[0][59] =  "6ED2AA";
$colors[0][60] =  "78DCA0";
$colors[0][61] =  "82E696";
$colors[0][62] =  "8CF08C";
$colors[0][63] =  "96FA82";
$colors[0][64] =  "A0F078";
$colors[0][65] =  "AAE66E";
$colors[0][66] =  "B4DC64";
$colors[0][67] =  "BED25A";
$colors[0][68] =  "C8C850";
$colors[0][69] =  "D2BE46";
$colors[0][70] =  "DCB43C";
$colors[0][71] =  "E6AA32";
$colors[0][72] =  "F0A028";
$colors[0][73] =  "FA961E";
$colors[0][74] =  "F08C14";
$colors[0][75] =  "E6820A";
$colors[0][76] =  "DC7800";
$colors[0][77] =  "D26E0A";
$colors[0][78] =  "C86414";
$colors[0][79] =  "BE5A1E";
$colors[0][80] =  "B45028";
$colors[0][81] =  "AA4632";
$colors[0][82] =  "A03C3C";
$colors[0][83] =  "963246";
$colors[0][84] =  "8C2850";
$colors[0][85] =  "821E5A";
$colors[0][86] =  "781464";
$colors[0][87] =  "6E0A6E";
$colors[0][88] =  "640078";
$colors[0][89] =  "5A0A82";
$colors[0][90] =  "50148C";
$colors[0][91] =  "461E96";
$colors[0][92] =  "3C28A0";
$colors[0][93] =  "3232AA";
$colors[0][94] =  "283CB4";
$colors[0][95] =  "1E46BE";
$colors[0][96] =  "1450C8";
$colors[0][97] =  "0A5AD2";
$colors[0][98] =  "0064DC";
$colors[0][99] =  "0A6EE6";
$colors[0][100] =  "1478F0";
$colors[0][101] =  "1E82FA";
$colors[0][102] =  "288CF0";
$colors[0][103] =  "3296E6";
$colors[0][104] =  "3CA0DC";
$colors[0][105] =  "46AAD2";
$colors[0][106] =  "50B4C8";
$colors[0][107] =  "5ABEBE";
$colors[0][108] =  "64C8B4";
$colors[0][109] =  "6ED2AA";
$colors[0][110] =  "78DCA0";
$colors[0][111] =  "82E696";
$colors[0][112] =  "8CF08C";
$colors[0][113] =  "96FA82";
$colors[0][114] =  "A0F078";
$colors[0][115] =  "AAE66E";
$colors[0][116] =  "B4DC64";
$colors[0][117] =  "BED25A";
$colors[0][118] =  "C8C850";
$colors[0][119] =  "D2BE46";
$colors[0][120] =  "DCB43C";
$colors[0][121] =  "E6AA32";
$colors[0][122] =  "F0A028";
$colors[0][123] =  "FA961E";
$colors[0][124] =  "F08C14";
$colors[0][125] =  "E6820A";
$colors[0][126] =  "DC7800";
$colors[0][127] =  "D26E0A";

# dark colors
$colors[0][0] = "5299AD"; # blue1
$colors[0][1] = "5D549A"; # violet
$colors[0][2] = "87B457"; # green
$colors[0][3] = "CF545E"; # red
$colors[0][4] = "CDDA13"; # lemon
$colors[0][5] = "5DAE99"; # turquise
$colors[0][6] = "DD844C"; # orange
$colors[0][7] = "AE5C8A"; # mauve
$colors[0][8] = "BD9F83"; # ltbrown
$colors[0][9] = "6B9BD4"; # blue2
$colors[0][10] = "B75F73"; #red-brown
$colors[0][11] = "646560"; # kaky
$colors[0][12] = "335098"; # deepblue
$colors[0][13] = "5FBFDB"; # bleu
$colors[0][14] = "D1CE85"; # yellow
$colors[0][15] = "909090"; # grey
$colors[0][16] = "A16254"; # brown
$colors[0][17] = "E8678D"; # pink
$colors[0][18] = "62B55A"; # deepgreen
$colors[0][19] = "A599AD"; # greypurple
$colors[0][20] = "6A5DD9"; # violet2
# light colors
$colors[1][0] = "98D6E7"; # blue1
$colors[1][1] = "9E7EDF"; # violet
$colors[1][2] = "BDDA83"; # green
$colors[1][3] = "EF747E"; # red
$colors[1][4] = "EDFA33"; # lemon
$colors[1][5] = "7EC392"; # tuquise
$colors[1][6] = "EDA46C"; # orange
$colors[1][7] = "DF93D7"; # mauve
$colors[1][8] = "E2BB91"; # ltbrown
$colors[1][9] = "A0CBEA"; # blue2
$colors[1][10] = "CB868B"; # red-brown
$colors[1][11] = "77897D"; # kaky
$colors[1][12] = "5370B8"; #deepblue
$colors[1][13] = "76DAF7"; # bleu
$colors[1][14] = "EAD770"; # yellow
$colors[1][15] = "AEAEAE"; # grey
$colors[1][16] = "B97A6F"; # brown
$colors[1][17] = "E8849D"; # pink
$colors[1][18] = "95D36E"; # deepgreen
$colors[1][19] = "B7AACF"; # greypurple
$colors[1][20] = "8A7DF9"; # violet2



print "\n";

# authenticate with zabbix
$auth = authenticate();
if (!$auth) {
	print "Auth failure\n\n";
	exit;
}

# get hostgroup list
$hostgroups = gethostgroups($auth);

# each hostgroup in list
foreach $hostgroup(@{$hostgroups->{result}}) {
	# get groupid and name
	$groupid = $hostgroup->{groupid};
	$name = $hostgroup->{name};
		
	# not templates or discovered hosts
	if ((lc($name) ne "templates") && (lc($name) ne "discovered hosts")) {		
		
		# get hosts list
		$hosts = gethosts($auth, $groupid);
		
		print "HOSTGROUP: ".$name." (".$groupid.")"."\n";		
		
		# each host in list
		foreach $host(@{$hosts->{result}}) {
			# get parent templates
			$templates = $host->{parentTemplates};
			# match results
			$templatematch = 0;			
						
			# each template in list
			# filter hosts that do not belong to our template
			foreach $templatei(@{$templates}) {
				# template name match
				if (lc($templatei->{name}) eq lc($template)) { $templatematch = 1; }
			}			
			
			# template match
			if ($templatematch == 1) {
				# get host id and name
				$name = $host->{name};
				$hostid = $host->{hostid};
				# reset graph item array
				@graph_item = ();
				
				print $config_indentation."HOST: ".$name." (".$hostid.")"."\n";
				
				#########
				# search for existing graphs and delete if found
				#########
				if ($config_recreate_graphs) {
					deletegraphs($auth, $hostid, $graph);
				}
		
				# get item list
				$items = getitems($auth, $hostid);
				$count = 0;
				# reset colorbase;
				$colorbase = 0;
				# reset colorindexes;
				@colorindex = 0;
				
				# each item in list
				foreach $item(@{$items->{result}}) {
						# get item name
						$item_name = $item->{name};
						#get item id
						$item_id = $item->{itemid};
						#get item key
						$item_key = $item->{key_};
						# reset regex index
						$regexindex = 0;
						# reset host item array
						@host_item = ();
						
						# each regex in list
						foreach $regex(@regexes) {						
						
							# item name match regex and item key is not prototype
							if (($item_name =~ /$regex/) && ($item_key !~ /.*{#.*}/))
							{																	
							print $config_indentation.$config_indentation."ITEM: ".$item_name." (".$item_id.")"."\n";
						
							# we may have exceeded color count, if so, use other base (light, ultralight)
							if ($colorindex[$regexindex] > $#{$colors[0]}) { 
								# move to next color base
								$colorbase++;
								# reset color index;
								$colorindex[$regexindex] = 0;
							
								print $config_indentation.$config_indentation."WARNING: Not enough colors, switched to another color base"."\n";
							}
						
							$graph_item[$count]->{itemid} = $item_id;
							$graph_item[$count]->{drawtype} = $drawtype;
							$graph_item[$count]->{sortorder} = $count;
							$graph_item[$count]->{color} = $colors[$colorbase + $regexindex][$colorindex[$regexindex]];
							$graph_item[$count]->{yaxisside} = "0";  ### 0=left, 1=right;
							$graph_item[$count]->{type} = "0"; 
							$graph_item[$count]->{calc_fnc} = $calcfunction;
						
							# inc count;
							$count++;
							# inc colorindex;
							$colorindex[$regexindex]++;
						}
						
						# inc regexindex
						$regexindex++;
					}
				}
				
				#########
				# create a new graph
				#########
				creategraph($auth, $graph, $graphtype, $mintype, $maxtype, $minvalue, $maxvalue, $showtriggers, \@graph_item, $hostid);
			}
		}
	}
}

print "\n";
