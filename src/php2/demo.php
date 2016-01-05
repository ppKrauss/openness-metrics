<?php
require_once 'SVGGraph/SVGGraphColours.php';
require_once 'SVGGraph/SVGGraph.php';
require_once 'omLib.php';

?>
<!DOCTYPE html>
<html lang="pt-BR">

<head>
	<meta charset="utf-8">
	<title>Openness Metrics, DEMO</title>
	<style>
	table.ometrics {
	    border: 2px solid #333;
	}
	table.ometrics tr:first-child td:first-child img:first-child {
		cursor: pointer;
	}

	table.ometrics td.ometrics-avg {
		text-align: center;
		background-color: #D0D0D0;
	}
	table.ometrics td.ometrics-od {
		text-align: center;
		background-color: #E0FFD0;
	}
	table.ometrics td.ometrics-oa {
		text-align: center;
		background-color: #F0F090;
	}
	table.ometrics td.ometrics-rt {
		text-align: center;
		background-color: #F59090;
	}
	</style>
	<script src="../assets/jquery-1.10.2.js"></script>
	<script>
		function boxToggle(id) {
			var $obj = $('#'+id);
			var $img = $obj.find('tr:first td:first img:first'); //.attr('src',minmax? '');
			if ( $obj.find('tr.ometrics-report').toggle().is(':visible') )
				src  = $img.attr('src').replace("maximize", "minimize");
			else
				src  = $img.attr('src').replace("minimize", "maximize");
			$img.attr('src',src);
		}
	</script>
</head>

<body>

<?php echo set_OpenMetricsBox(
	['DOAJ','pt','DOAJ Seal 2015', 
	 'As <i>licenças default</i> utilizadas pelas 5302 revistas certificadas do diretório DOAJ de revistas OpenAccess 
	 serviram de fonte uniforme (igual peso independente da revista) para a caracterização do DOAJ.  
	 A maior parte das revistas, 5196, declararam licenças conhecidas: 50% apresentaram licença da família CC­-BY, 
	 2% família CC­-BY­-SA, ou seja, 52% (2702 revistas) apresentaram licenças Open Definition.'
        ], 
	['od'=>53, 'oa'=>47], 
	['od'=>6, 'oa'=>2.0], '480', true, 200
); ?>

<p>&nbsp;</p>
<?php echo set_OpenMetricsBox(
	['scieloBR','pt','SciELO-BR 2015',
	 'AS licenças default utilizadas pelas 343 revistas são CC-BY-NC-v4, 83%; CC-BY-v4, 14%; e CC-BY-NC-ND-v4, 3%.'
	],
	['oa'=>86, 'od'=>14],
	['od'=>6, 'oa'=>2.9], '480', true, 200
); ?>

<h2>DEMO</h2>

<?php echo set_OpenMetricsBox(['demo1','pt','Coleção Tal','nonon  nonoonnon  nonononoonon'], ['od'=>50, 'oa'=>45.9, 'rt'=>4.1], ['od'=>5, 'oa'=>3, 'rt'=>-1], '480', true, 200); ?>

<p>&nbsp;</p>
<?php echo set_OpenMetricsBox(['demo2','en','Repo Tal2','blabla inglês bla blablabla blabla bla bla blabla'], ['od'=>55, 'oa'=>45], ['od'=>5, 'oa'=>3], '480', true, 200); ?>

<hr/>

<img src="../assets/hoii-guide-OAdegreeTable.png">

</body>
</html>

