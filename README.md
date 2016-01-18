## How much open is it?
This project is an initiative to shift the traditional conversations about [Open access](https://en.wikipedia.org/wiki/Open_access), from “Is it open access?”, “How to compare open things?”... to "How much open is it?",  and transform consensual answers into concrete things!

It is a technical response, creating a reference-database, foundations for *openness metrics*, and a concrete set of online tools. Differing from [OAS](http://www.oaspectrum.org) the focus of this tools are the autit of license type of each document, and distribution of license types over the set of documents.

# The Openness Metrics project
A mini-framework to check the license of a work (document, software and others), express its openness degree, and calculate the average of openness degree of a set of works.

The main sources of this project are:

* [families](data/families.csv): Families of licenses and openness degree definition (many def versions). [Get original sources as formated spreadsheet or comment here](https://docs.google.com/spreadsheets/d/1nf3vFHcLpgVTcFbUJp8pL3H8fsBFvjrWA07AI2JZtk8/edit?usp=sharing).

* [licenses](https://github.com/ppKrauss/licenses): licenses dataset, to feed the PostgreSQL database.

![uml class diagram](_doc/uml_diagram.png)

# Prepare

Feed the database, and install the demo and webservice as a `ometrics` in the http server (ex. folder `html` of standard Apache),

```
cd yourSandBox
git clone https://github.com/ppKrauss/licenses.git
git clone https://github.com/ppKrauss/openness-metrics.git
nano openness-metrics/src/php/omLib.php  # change configs as $PG_PW
php openness-metrics/src/php/ini.php     # feed database

mv openness-metrics/src/php /var/www/html/ometrics
mv openness-metrics/src/assets /var/www/html/ometrics
sudo chmod -R g+rwx /var/www/html/ometrics

rm -r openness-metrics; rm -r licenses # optional
```

# Links and references

* Open Access Organizations
 * [DOAJ](https://doaj.org/) - Directory of Open Access Journals
   * http://www.oaspectrum.org/faq
   * http://www.oaspectrum.org/api
 * [OAS](http://www.oaspectrum.org/) - Open Access Spectrum
 * [SPARC](http://sparcopen.org/) - the Scholarly Publishing and Academic Resources Coalition
   * http://www.sparc.arl.org/blog/announcing-open-access-spectrum-oas-evaluation-tool
   * https://community.cochrane.org/editorial-and-publishing-policy-resource/open-access#HowOpenScale
 * [OASPA](http://oaspa.org/) - Open Access Scholarly Publishers Association

* Initiatives (projects, programs, etc. of the organizations)
 * http://www.howopenisit.org The "HowOpenIsIt?" program is a family of resources and services ... as OAS. Was developed by PLOS, SPARC, and OASPA.
 * http://ananelson.github.io/oacensus/
 * https://www.plos.org/wp-content/uploads/2014/10/hoii-guide_V2_FINAL.pdf

* Scientific Open Access content (articles)
 * [SciELO](http://www.scielo.org/) - half million of articles
 * [PubMed Central](http://www.ncbi.nlm.nih.gov/pmc/) - 3.7 million of articles

* Other
 * [Ordering of Creative Commons licenses](https://commons.wikimedia.org/wiki/File:Ordering_of_Creative_Commons_licenses_from_most_to_least_open.png) - ordering of CC licenses illustration
 * ...
