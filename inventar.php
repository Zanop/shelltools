#!/usr/bin/php
#
# (c) 2015 Vladimir Smolensky <arizal@gmail.com> under the GPL
#     http://www.gnu.org/licenses/gpl.html
#
<?

require_once("libs/invlib.php");

#$rps = array_merge( get_hosts('rp', 'us'), get_hosts('rp','nl'));
#
#foreach( $rps as $rp )
#{
#     $host = host($rp['domain']);
#     echo "Host: $host "; echo print_r(query_host_ssh($host, $squery['totalmem']));  echo "\n";
#     echo print_r(query_host_ssh($host, $squery['megapdlist']));  echo "\n";
#
#}
#
$rps = array_merge( get_hosts('rp', 'us'), get_hosts('rp','nl'));

foreach( $rps as $rp )
{
     $host = short_host($rp['domain']);
     echo "Host: $host "; 
//        print_r(get_host_nic_speed($host));
        print_r(get_host_pdlist($host));
        echo "\n";

}
?>
