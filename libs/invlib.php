#!/usr/bin/php
#
# (c) 2015 Vladimir Smolensky <arizal@gmail.com> under the GPL
#     http://www.gnu.org/licenses/gpl.html
<?


$ml = mysql_connect('localhost', 'root', '');
      mysql_select_db('cdn_config');

$mquery = array( 
                'hostlist'  => "select hostname, domain, ip from hosts"
              );
$squery = array(
                'totalmem'  => "free -m | grep 'Mem: ' | awk '{ print $2 }'",
                'usedmem'  => "free -m | grep 'Mem: ' | awk '{ print $3 }'",
                'megapdlist' => "/opt/bin/megacli -pdlist -a0 | grep 'Inquiry Data:'",
                'ifup' => "/sbin/ip link show | grep 'state UP' | awk '{ print $2 }' | cut -f1 -d:",
                'ifspeed' => "ethtool %s | grep 'Speed: '",
                'ifspeed2' => 'ethtool `/sbin/ip link show | grep "state UP" | awk "{ print $2 }" | cut -f1 -d: ` | grep "Speed: " ',
                'iptinput' => "iptables -L INPUT --line-numbers -vxn | grep -vE '^[^0-9]'",
                'iptoutput' => "iptables -L INPUT --line-numbers -vxn | grep -vE '^[^0-9]'",
                'iptforward' => "iptables -L INPUT --line-numbers -vxn | grep -vE '^[^0-9]'",
                'megapdlists' => "/opt/bin/megacli -pdlist -a0 | grep 'Slot Number:' | awk '{ print $3}'",
                'ssdlifetime' => "smartctl -a -d sat+megaraid,%s /dev/sda | grep '231 Temperature_Celsius' | awk '{ print $4 }'"
            );

function ssh_exec($host, $cmd)
{
    exec("ssh -p3333 root@$host $cmd", $out);
    return($out);
}

function get_fail_ssd($host) 
{
    global $squery;
    $ssdlist=array();
    $slots = query_host_ssh($host, 'megapdlists');
    foreach( $slots as $slot ) 
    {
        @list( $ssdlife ) = query_host_ssh($host, 'ssdlifetime', $slot);
    //    printf($squery['ssdlifetime'], $slot); echo "\n";
        if( @is_numeric($ssdlife) && ($ssdlife < 30) )
        {
            $ssdlist[$slot] = $ssdlife;
        }
    }
    return $ssdlist;
}
#generate queries
function get_hosts($role, $loc) 
{
    global $mquery;
    $where = "domain LIKE '$role%-$loc%.cdn-project.info'";
    $listq = "${mquery['hostlist']} WHERE $where";
    if( ($res = mysql_query($listq)) == FALSE ) return(-1);
    while($row = mysql_fetch_assoc($res) ) 
            $ret[]=$row;
    return($ret);
}

function short_host($fqdn)
{
    preg_match("/^(.*?)\.(.*)/", $fqdn, $rest);
    return($rest[1]);
}

function query_host_ssh($host, $cmd, $arg1 = null, $arg2 = null, $arg3 = null) 
{
    global $squery;
    if( ! array_key_exists($cmd, $squery) ) 
    {
        die("No such ssh query: '$cmd'!");
    }
    $out = ssh_exec($host, sprintf( $squery[$cmd], $arg1, $arg2, $arg3));
    return($out);
}

function get_host_nic_speed($host) 
{
    $ifuplist = query_host_ssh($host, 'ifup');
    foreach($ifuplist as $if)
    {
        list( $speeds[$if] ) = query_host_ssh($host, 'ifspeed', $if);  
    }
    return $speeds;
}

function get_host_pdlist($host)
{
    $pdlist = query_host_ssh($host, 'megapdlist');
    return $pdlist;
    
}

function get_host_totalmem($host)
{
    $pdlist = query_host_ssh($host, 'totalmem');
    return $pdlist;
    
}
function get_host_fw($host, $chain) 
{
    switch($chain) 
    {
        case 'input':
            $cmd='iptinput';
            break;
        case 'output':
            $cmd='iptoutput';
            break;
        case 'forward':
            $cmd='iptforward';
            break;
        default:
            $cmd='iptinput';
    }
    $rules = query_host_ssh($host, $cmd);

    foreach( $rules as $line ) 
    {
        list($num, $pkts, $bytes, $target, $prot, $opt, $in, $out, $source, $destination) = preg_split('/\s+/', $line);
        $iptout[] = array(
                        'pkts' => $pkts,
                        'bytes' => $bytes,
                        'target' => $target,
                        'prot' => $prot,
                        'opt' => $opt,
                        'in' => $in,
                        'out' => $out,
                        'source' => $source,
                        'destination' => $destination
                    );
    }
    return($iptout);
}

# print_r(get_hosts());
get_host_pdlist('rp24-nl0.cdn-project.info');
?>
