<?php
/**
 * Webservice to input (by JSON, POST or GET) pairs of key-value
 * representing license names or license-family names and quantities.
 * Receive by http://stackoverflow.com/a/18867369/287948
 * REST: http://stackoverflow.com/a/4573426/287948
 */
// VER completo http://silex.sensiolabs.org/doc/cookbook/json_request_body.html
// header para devolver JSON
// uso http://localhost/openness-metrics/src/php/ws.php?cc-by=2&cc-by-nc=22&cc-by-sa=3&cc0=1&cc-by-nd=5&degvers=3
// testes com http://localhost/openness-metrics/src/php/ws.php?cc-by=2&cc-by-nc=22&cc-by-sa=3&cc0=1&cc-by-nd=5&degvers=3
//            http://localhost/openness-metrics/src/php/ws.php?list=cc-by;cc-by-nc;cc0;cc-by;cc-by-sa;cc0;cc-by-nd;cc0&degvers=2
// user: http://php.net/manual/en/httprequest.send.php
//  localhost/openness-metrics/src/php/ws.php?

require_once 'omLib.php';
$outmode = 'json';
//IMPLENTAR AS DIFERENTES RESPOSTAS ... Depois o httaccess para endpoints mais amigaveis


/* CONTROLLER AND PARAMETER COMPOSER */
// GET/POST context RESERVED WORDS: cmd, list, degvers, params, method, licenses, families.
// (for JSON requests no problem)
	checkrequest($outmode,'$outmode'); 		// optional
	checkrequest($callerID,'id'); 		// optional
	checkrequest($jsonrpcVers,'jsonrpc');	// optional
	checkrequest($cmd,'cmd');
	if (!$cmd) checkrequest($cmd,'method'); // cmd alias
	if (!$cmd) $cmd='qts_calc';
	checkrequest($degVers,'degvers');
	checkrequest($list,'list');
	if (!$list) checkrequest($list,'params');		// list alias
	if (!$list) checkrequest($list,'licenses',$is_cmdLic);	// list alias + cmd restriction
	if (!$list) checkrequest($list,'families',$is_cmdFam);	// list alias + cmd restriction

	if ($is_cmdLic)
		$is_cmdFam = false;
	elseif ($is_cmdFam)
		$is_cmdLic = false;

	if ( preg_match('/^(?:(fam)|(lic))/i',$cmd,$m) ) {
		$is_cmdFam = $m[1]? true: false;
		$is_cmdLic = !$is_cmdFam;
	} else
		$cmd = ($is_cmdFam? 'fam': 'lic').$cmd;

$LST = [];
if ($list)
	$LST = array_combine_sum( explode(';',$list) );
else
	foreach($_REQUEST as $k=>$v) if (strlen($k)>2 && is_numeric($v))
		$LST[$k]=(float) $v;


$jresult = request_ws($cmd,$LST,$degVers);

if ($outmode=='json') {
  header('Content-Type: application/json');
  print $jresult;
} else {
	$aux = json_decode($jresult);
	var_dump($aux);
}

?>
