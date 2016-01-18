<!DOCTYPE html>
<html lang="pt">
<head>
	<meta charset="utf-8">
	<title>Openness Metrics, DEMO</title>
	<link rel="stylesheet" href="../assets/ui-1.11.4.cust/jquery-ui.min.css">
		<!-- or online //code.jquery.com/ui/1.11.4/themes/smoothness/jquery-ui.css-->
	<link rel="stylesheet" href="../assets/ometrics.css">
	<script src="../assets/jquery-1.10.2.js"></script><!-- or online //code.jquery.com/jquery-1.10.2.js -->
	<script src="../assets/ui-1.11.4.cust/jquery-ui.min.js"></script><!-- or online //code.jquery.com/ui/1.11.4/jquery-ui.js -->
	<script src="../assets/etc_lib.js"></script><!-- g_state -->

	<script>

	var exemplos = [  // parametros set_OpenMetricsBox_byFamList()
		{ xid: 'DOAJ2'
		 ,title: 'DOAJ Seal 2015' 
		 ,msg_pt: "pt As licenças default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,msg_en: "en licenses default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,lst_type: 'families'
		 ,lst: {  // DOAJ DEFAULT LICENSE FAMILIES
			'CC BY':	2604,
			'CC BY-SA':	112,	
			'CC BY-NC-ND':	1162,
			'CC BY-NC':	938,
			'CC BY-NC-SA':	333,
			'CC BY-ND':	47
			}
		},

		{ xid: 'sci2'
		 ,title: 'SciELO Defaults 2015' 
		 ,msg_pt: "xx pt licenças default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,msg_en: "xx en licenses default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,lst_type: 'families'
		 ,lst: {  // SCIELO DEFAULT LICENSE FAMILIES
			'CC-BY-NC':	83,
			'CC-BY':	14,	
			'CC-BY-NC-ND':	3
			}
		},
		{ xid: 'acme1'
		 ,title: 'ACME collection' 
		 ,msg_pt: "xx pt licenças default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,msg_en: "xx en licenses default utilizadas pelas ... #stdDev# ... revistas são #RELAT#. #STDREPORT#"
		 ,lst_type: 'families'
		 ,lst: {  // SCIELO DEFAULT LICENSE FAMILIES
			'CC-BY-NC':	83,
			'CC-BY':	14,	
			'CC-BY-NC-ND':	3
			}
		}

	];


	g_state.onChangeHub = function (id,obj,params) { 
		switch(id) {  // EACH STATE-CHANGE (by DOM id)
		    case 'lang0':
		    case 'degvers':
		    case 'exemp':
			return $(obj).val();
		    default:
			return null;
		}
	};
	var langMsg = { // lang-template variables and its possible values
		'pt':{langlabel:'Idioma', 	degvers:'Métrica de abertura, versão',
			exemp:'Exemplos', 	thead: 'Medida do grau de abertura de um conjunto de obras pelas suas licenças',
			submit:'PERSONALIZAR'
		},
		'en':{langlabel:'Language', 	degvers:'Openness metric, version',
			exemp:'Examples', 	thead: 'Measure of the openness degree in a set of works by its licenses',
			submit:'CUSTOMIZE'
		}
	}
	function chg_byLang(lang,exIdx) { //  set vars for lang-template's placeholders
			var $f = $('fieldset:has(#lang0)');
			var lm = langMsg[lang];
			$('body h2:first')			.html(lm.thead);
			$f.find('label:first')			.html(lm.langlabel);
			$f.find('label[for="degvers-button"]')	.html(lm.degvers);
			$('label[for="exemp-button"]')		.html(lm.exemp);
			$('#submit0')	.val(lm.submit);
			$('#p_msg')	.val(exemplos[exIdx]['msg_'+lang]);
	}

	g_state.afterChangeHub = function (id,obj,params) { 
		switch(id) {  // EACH STATE-CHANGE (by DOM id)
		    case 'lang0':
			chg_byLang(this.lang0, this.exemp.substr(-1, 1));
		    case 'degvers':
			var fname = '../assets/famDegree-v'+ this.degvers +'-'+ this.lang0 +'.png';
			$('#famDegree').attr('src',fname);
			return true;

		    case 'exemp':
			var exIdx = this.exemp.substr(-1, 1);
			chg_byLang(this.lang0, exIdx);
			$('#p_id'). 	  val(exemplos[exIdx].xid);
			$('#p_title'). 	  val(exemplos[exIdx].title);
			$('#p_lst_type'). val(exemplos[exIdx].lst_type);
			$('#p_lst').	  val( Object.keys(exemplos[exIdx].lst).join() );
			return true;

		    default:
			alert("ERROR on g_state,\n case "+ id +" not implemented");
			return false;
		}
	};

	$(function() { // ONLOAD

		for(var selmenu_id of ['#lang0', '#degvers','#exemp']) {
			var $obj = $(selmenu_id);

			g_state.ini( $obj, $obj.val() );
			$obj.selectmenu({
				change: function( event, data ) { 
					if (!g_state.chg(this,'debug')) alert("no changes"); 
				}
			});
		}

	}); // onload

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
  <style>
	h2 {
		font-size: 130%;
		margin: 0;
		padding: 0;
	}
    /*  #####  LEFT SELECTOR LAYOUT ##### */
    fieldset {
      border: 0;
      margin-right: 5pt;
    }
    label {
      display: block;
      margin: 20px 0 0 0;
    }
    select {
      width: 280px;
    }
     #exBlock, #selectedContent {
      background: #CCF;
    }
    #selectedContent {
	height: 100%;
	min-height: 400px;
	}

    /* #####  OM (OPENNESS-METRIC) BOXES ##### */


  </style>
</head>
<body>
<!--
 http://localhost/openness-metrics/src/php/demo3.php?degvers=1
-->

<h2>Medida do grau de abertura de um conjunto de obras pelas suas licenças</h2>

<form action="#">

<table border="0" width="99%">
<tr>
<td width="30%">
   <fieldset>
    <label for="lang0">Idioma</label>
    <select name="lang0" id="lang0">
      <option value="pt" selected="selected">pt - Português</option>
      <option value="en">en - English</option>
    </select>
 
    <label for="degvers">Métrica de abertura, versão</label>
    <select name="degvers" id="degvers">
      <option value="1">v1 (0-7 with NC&lt;ND)</option>
      <option value="2" selected="selected">v2 (0-100 with ND&lt;NC)</option>
    </select>
    <br/>
   <a title="metrics description" target="_blanck" 
     href="https://commons.wikimedia.org/wiki/File_talk:Ordering_of_Creative_Commons_licenses_from_most_to_least_open.png"
     ><img id="famDegree" width="280" src="../assets/famDegree-v1-pt.png"></a>
  </fieldset>
</td>

<td width="70%" valign="top">
		<label for="exemp">Exemplos</label>
		<select name="exemp" id="exemp">
		<optgroup label="Real collections">
		      <option value="ex0">DOAJ profile</option>
		      <option value="ex1" selected="selected">SciELO-BR profile</option>
		</optgroup>
		<optgroup label="Fake (demo)">
		      <option value="ex2">ACME collection</option>
		      <option value="ex3">yyyy</option>
		</optgroup>
		<!-- option value="exP">PERSONALIZADO</option -->
		</select>
	<br><div id="selectedContent"> BLOCO AQUI</div>
</td>
<tr>
<td colspan="2" id="exBlock">
   <fieldset>

		<br/><tt>id</tt> <input type="text" id="p_id" name="p_id" size="12"/> &#160;&#160;&#160; &#160;&#160;&#160; 
		     <tt>title</tt> <input type="text" id="p_title" name="p_title" size="30"/>
		<br/><tt>lst_type</tt> <input type="text" id="p_lst_type" name="p_lst_type" size="12"/> &#160;&#160;&#160; &#160;&#160;&#160; 
		     <tt>lst</tt> <input type="text" id="p_lst" name="p_lst" size="70"/>
		<br/>
		<br/><tt>msg</tt> <input type="text" id="p_msg" name="p_msg" size="70"/> &#160;&#160;&#160; &#160;&#160;&#160; 
		&#160;&#160;&#160; &#160;&#160;&#160; <input type="submit" id="submit0" name="submit0" value="PERSONALIZAR"/>
   </fieldset>
</td>
</tr>
</table>
  
</form>

<p>&#160;</p>

</body>
</html>

