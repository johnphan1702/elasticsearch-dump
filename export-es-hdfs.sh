#!/bin/sh

v_date=`date +%Y%m%d`

today=$v_date
yesterday=`date -d '-1 day' '+%Y%m%d'`

# es_location="http://es_rad.sendo.vn/sendo_new_filter_left_alias/product"
# es_query_body={"query": {"bool": {"must_not": [{"exists": {"field": "Brand_Or_Shop_Hoa_Sen_Boost"}}]}}, "_source": ["Status","Status_new","Stock_status","Name","Default_listing_score","Category_id","Brand_id","Product_id","External_id","Admin_id","Order_count.Dd_1000_cod","Total_comment","Rating_percent","Brand_id","Final_price","Created_at","Updated_at","Price","Final_price","Cat_path","Image","Is_promotion","Promotion_percent","Order_count","Shop_info","Rating","Rating_percent"]}
# es_query_limit=1000

hadoop_path="hdfs://localhost:9000/user/nguyen/data/ES"
es_location="http://localhost:9200/sendo/product"
es_query_limit=1000
es_query_body={"query": { "match_all": {} }, "_source": true }

file_output="/home/nguyen/logs/demo/sendo_product_${today}"

# for retry in 1 2 3
for retry in 1
do 
	rm -f  $file_output
	echo "Start dump data: `date +%Y-%m-%d`"

    dump_info="--input=${es_location} --output=${file_output} --type=data --sourceOnly=true --limit=${es_query_limit} --overwrite=true --ignore-errors=true --searchBody=`'${es_query_body}'`"
    ./bin/elasticdump ${dump_info}

	echo "Start check on hdfs: `date +%Y-%m-%d`"
	
    # yesterday_lines=`sudo -u hdfs hadoop fs -cat "$hadoop_path/$yesterday" | wc -l`
    yesterday_lines=`hadoop fs -cat "$hadoop_path/$yesterday" | wc -l`
	
    today_lines=`cat $file_output | wc -l`

	min=`echo 0.95*$yesterday_lines/1 | bc`

	echo "today lines: $today_lines, yesterday records: $yesterday_lines, => min: $min"


	if [ "$today_lines" -lt "$min" ]; then
		echo "Error found, records must be at least 95% of yesterday records retry at: $retry th"
		if [ "$retry" -eq 3 ]; then
			echo "retry reach the limit, copy yesterday data to current data"

			# sudo -u hdfs hadoop fs -put $file_output "$hadoop_path/${v_date}_debug"
			# sudo -u hdfs hadoop fs -cp "$hadoop_path/$yesterday" "$hadoop_path/$today"
            hadoop fs -put $file_output "$hadoop_path/${v_date}_debug"
			hadoop fs -cp "$hadoop_path/$yesterday" "$hadoop_path/$today"
		fi
	else
		echo "DUMPING OK, copy or replace HDFS file"
		# sudo -u hdfs hadoop fs -rm "$hadoop_path/$v_date"
		# sudo -u hdfs hadoop fs -put $file_output "$hadoop_path/$v_date"
        hadoop fs -rm "$hadoop_path/$v_date"
		hadoop fs -put $file_output "$hadoop_path/$v_date"
	    break
	fi
done
