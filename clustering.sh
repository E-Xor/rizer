#!/bin/sh

cd $MAHOUT_DIR/bin
hadoop fs -put /root/mounts/mahout-examples/synthetic_control.data.txt /mahout_data/
./mahout seqdirectory -i /mahout_data/ -o /mahout_seq2/ -xm sequential
./mahout seq2sparse -i /mahout_seq2/ -o /mahout_vector4/ --maxDFPercent 100
./mahout kmeans -i /mahout_vector4/tfidf-vectors -c /clustered_data_tmp -o /kmeans_output -dm org.apache.mahout.common.distance.EuclideanDistanceMeasure -x 10 -k 20 -ow --clustering
./mahout clusterdump -i /kmeans_output/clusters-1-final -p /kmeans_output/clusteredPoints -dt sequencefile -d /mahout_vector4/dictionary.file-0
