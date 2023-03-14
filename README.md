# dupe

    dupels [<dir> ...] >dupels.txt

    awk '$1 == "v1" && $4 >= 1048576' dupels.txt | sort -n >dupelarge.txt
    awk '$1 == "v1" && $4 < 1048576' dupels.txt | sort -n >dupesmall.txt

    dupefind <dupelarge.txt >dupermlarge.sh
    dupefind <dupesmall.txt >dupermsmall.sh

    sh dupermlarge.sh
    sh dupermsmall.sh
