<?

// Usage example: ip_in_net('192.168.0.0/24', '192.168.0.23') 
function ip_in_net($network, $ip)
{
        @list( $net, $mask) = explode('/', $network);
        if(!$mask) $mask=32;
        $bmask = (pow(2,$mask)-1) << (32-$mask);
        $bnet  = ip2long($net) & $bmask;
        if( ( ip2long($ip) & $bmask ) === $bnet ) return(1);
        return(0);
}

?>
