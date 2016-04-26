#!/bin/sh

cd $MAHOUT_DIR/bin
# http://192.168.99.100:50070/

# Cleaning
hadoop fs -ls / | tail -n+2 | awk '{ print $8 }' | xargs hadoop fs -rm -r -f

# Copy
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate/20news-bydate-test/* /news-all
hdfs dfs -put /root/mounts/mahout-examples/20news-bydate/20news-bydate-train/* /news-all


hadoop fs vs hdfs

# Classification
./mahout seqdirectory -i /news-all -o /news-seq -ow

./mahout seq2sparse -i /news-seq -o /news-vectors -lnorm -nv -wt tfidf

./mahout split \
        -i /news-vectors/tfidf-vectors \
        --trainingOutput /news-train-vectors \
        --testOutput /news-test-vectors \
        --randomSelectionPct 40 \
        --overwrite --sequenceFiles -xm sequential

./mahout trainnb \
        -i /news-train-vectors \
        -o /news-model \
        -li /news-labelindex \
        -ow \
        -c

./mahout testnb \
        -i /news-test-vectors \
        -m /news-model \
        -l /news-labelindex \
        -ow \
        -o /news-testing \
        -c > /root/mounts/mahout-examples/news-testing.txt 2>&1

# No C
hdfs dfs -rm -r -f /temp

./mahout trainnb \
        -i /news-train-vectors \
        -o /news-model-no-c \
        -li /news-labelindex-no-c \
        -ow

./mahout testnb \
        -i /news-test-vectors \
        -m /news-model-no-c \
        -l /news-labelindex-no-c \
        -ow \
        -o /news-testing-no-c > /root/mounts/mahout-examples/news-testing-no-c.txt 2>&1

