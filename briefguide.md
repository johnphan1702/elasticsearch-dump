# INSTRODUCTION

## Step 1: going to root folder of project
```bash
cd ~/gitmp/elasticsearch-dump
```
## Step 2: install library
```bash
npm install
```

## Step 3: run job

```bash
./bin/elasticdump --input=http://localhost:9200 --input-index=myidenx/mytype --output=/logs/demo_product.txt --type=data --sourceOnly=true --limit=100 --overwrite=true --ignore-errors=true --searchBody='{"query": {"bool": {"must_not": [{"exists": {"field": "fieldname"}}]}}, "_source": ["fieldname1","fieldname2"]}'

```
