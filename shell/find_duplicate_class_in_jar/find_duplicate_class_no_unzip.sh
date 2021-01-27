tmp_file_list_dir=tmp_file_list2
output=duplicate_classes2.txt
output_detail=duplicate_jars_classes2.txt

>$output
>$output_detail

[ -d $tmp_file_list_dir ] || mkdir $tmp_file_list_dir

for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do

    unzip -lv $file | awk '{if(length($3)!="0" && index($8,"/")>0 && $8 ~ "^.*/.*.class$"){print $8,$7}}' | grep -v 'META-INF' | sort | uniq >"$tmp_file_list_dir"/"$file"-list.txt
done

echo 查找重复同名类

cat "$tmp_file_list_dir"/*-list.txt | awk '{print $1}' | sort | uniq -c | sort -r -n -k 1 | awk '{if($1>1){print $2}}' | sort >$output

cat $output | while read file; do
    echo "处理文件 $file"

    grep $file "$tmp_file_list_dir"/*-list.txt | awk -F "$tmp_file_list_dir/" '{print $2}' >>$output_detail

    num=$(grep $file "$tmp_file_list_dir"/*-list.txt | awk '{print $2}' | sort | uniq | wc -l)
    [ $num -gt 1 ] && echo "!!! not equals" >>$output_detail

    echo >>$output_detail
done

echo "output: $output"
echo "output_detail: $output_detail"
