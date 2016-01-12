<?php
/**
 * Scans and charges CSV data to the SQL database.
 * See also scripts at "ini.sql" (run it first!).
 * php openness-metrics/src/php/ini.php
 */

include 'omLib.php';  
// include 'doaj_get.php';  // for check openness degree of citations in sciDocs. 


// // // // //
// SQL PREPARE
$items = [
	'openness-metrics'=>[
		array('INSERT INTO om.license_families(fam_name,fam_info) VALUES (:family::text, :json_info::JSONB)',
			'families.csv::strict'
		), 
		// array(..., 'scopes.csv')
	],
	'licences'=>[
		//IGNORES families.csv of licences package:
		//array('INSERT INTO om.license_families (fam_name,fam_info) VALUES (:family::text, :json_info::JSON)',
		//	'families.csv'
		//),
		array('SELECT om.licenses_upsert(
			:id_label::text, :id_version::text, :name::text, :family::text, NULL::text, :json_info::jsonB
			)',
			'implieds.csv::bind','licenses.csv::bind'
		)
		,array('SELECT om.licenses_upsert(
                               :id_label::text, :id_version::text, :name::text, :family::text, :name_of_equiv::text, :json_info::jsonB
			)',
			'redundants.csv::bind'
		)
	],
];

$sql_delete = " -- prepare to full refresh of om.scheme
	DELETE FROM om.licenses         WHERE substring(lic_id_label,1,1)!='(';
	DELETE FROM om.license_families WHERE substring(fam_name,1,1)!='(';
";

// // //
// INITS:

//FALTA informar do erro de um exec.

$db = new pdo($dsn,$PG_USER,$PG_PW);

if ($reini)
	sql_exec($db,  file_get_contents($projects['openness-metrics'].'/src/ini.sql')  );
sql_exec($db,$sql_delete);

print "BEGIN processing ...";

list($n2,$n,$msg) = jsonCsv_to_sql($items,$projects,$db);

print "$msg\n\nEND(tot $n lines scanned, $n2 lines used)\n";
?>

