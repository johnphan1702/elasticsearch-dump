#!/bin/sh

v_date=`date +%Y%m%d`

today=$v_date
yesterday=`date -d '-1 day' '+%Y%m%d'`

hadoop_path="hdfs://localhost:9000/user/<name>/data/ES"
es_location="http://localhost:9200/sdo/product"
es_query_limit=1000
es_query_body={"query": { "match_all": {} }, "_source": true }

file_output="/logs/demo/product_${today}"

for retry in 1
do 
	rm -f  $file_output
	echo "Start dump data: `date +%Y-%m-%d`"

    dump_info="--input=${es_location} --output=${file_output} --type=data --sourceOnly=true --limit=${es_query_limit} --overwrite=true --ignore-errors=true --searchBody=`'${es_query_body}'`"
    ./bin/elasticdump ${dump_info}

    echo "Start check on hdfs: `date +%Y-%m-%d`"
    yesterday_lines=`hadoop fs -cat "$hadoop_path/$yesterday" | wc -l`
	
    today_lines=`cat $file_output | wc -l`

	min=`echo 0.95*$yesterday_lines/1 | bc`

	echo "today lines: $today_lines, yesterday records: $yesterday_lines, => min: $min"


	if [ "$today_lines" -lt "$min" ]; then
		echo "Error found, records must be at least 95% of yesterday records retry at: $retry th"
		if [ "$retry" -eq 3 ]; then
            		hadoop fs -put $file_output "$hadoop_path/${v_date}_err"
			hadoop fs -cp "$hadoop_path/$yesterday" "$hadoop_path/$today"
		fi
	else
		echo "DUMPING OK, copy or replace HDFS file"
        	hadoop fs -rm "$hadoop_path/$v_date"
		hadoop fs -put $file_output "$hadoop_path/$v_date"
	    break
	fi
done
