find_rows=$1

classes_dir_file=in_classes_dir.txt
config_dir_file=in_config_dir.txt
current_time=$(date +%Y%m%d-%H%M%S)
classes_info_dir=result_classes_info
used_jars_by_class_dir=result_used_jars_by_class
unused_jars_dir=result_unused_jars
unused_jars_result=""
check_rows=1
run_log_dir=run_log
run_log_file="$run_log_dir"/run_prepare-"$current_time".log

find_in_dir=find_in
find_in_class_dir_file=""
find_in_conf_dir_file="$find_in_dir"/find_in_conf_dir.txt

log_run() {
    echo $1
    echo $1 >>$run_log_file
}

unzip_jars() {
    for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do
        [ ! -d "$file"-dir ] && unzip -o $file -d "$file"-dir-tmp && mv "$file"-dir-tmp "$file"-dir
    done
}

check_jar_use() {
    jar_name=$1
    find_in_dir_file=$2
    find_class=$3
    jar_dir="$jar_name"-dir
    jar_dir_compare=./"$jar_dir"
    used_jars_file="$used_jars_by_class_dir"/"$jar_name".txt
    content_slash_point_file="$classes_info_dir"/"$jar_name"_slash_point.txt
    content_point_file="$classes_info_dir"/"$jar_name"_point.txt

    cat $find_in_dir_file | while read find_dir; do
        [ -d $find_dir ] || continue

        if [ "$find_dir" == "$jar_dir_compare" ]; then
            log_run "跳过在以下目录中查找是否有使用当前包 $jar_name $find_dir"
            continue
        fi

        if [ $find_class -eq 1 ]; then
            log_run "查找以下Jar包在当前目录中的.class文件是否有使用 $content_slash_point_file $find_dir"
            find $find_dir -type f -name \*.class | xargs grep -a -o -f $content_slash_point_file | head -$check_rows >$used_jars_file
        else
            log_run "查找以下Jar包在当前目录中的.xml等文件是否有使用 $content_point_file $find_dir"
            find $find_dir -type f -iname \*.xml -o -iname \*.properties -o -iname \*.groovy | xargs grep -o -f $content_point_file --exclude=*"$jar_dir"/* | head -$check_rows >$used_jars_file
        fi

        num=$(head -1 $used_jars_file | wc -l)
        if [ $num -eq 1 ]; then
            log_run "以下目录有使用当前Jar包 $jar_name $find_dir"
            return 1
        fi
    done

    return $?
}

gen_classes_info() {
    for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do
        log_run "生成Jar包的类名信息 $jar_name"

        jar_name=$(echo $file | awk -F '/' '{print $2}')
        jar_dir="$jar_name"-dir
        classes_slash_point_file="$classes_info_dir"/"$jar_name"_slash_point.txt
        classes_point_file="$classes_info_dir"/"$jar_name"_point.txt

        find $jar_dir -mindepth 2 -type f -name \*.class | awk -F "$jar_dir/" '{print $2}' | grep -v META-INF | awk -F '\\.class' '{print $1}' | awk -F '$' '{print $1}' | sort | uniq | sort >$classes_slash_point_file
        cat $classes_slash_point_file | sed "s#/#\\\\.#g" >$classes_point_file
        cat $classes_point_file >>$classes_slash_point_file
    done
}

next_round() {
    unused_jars_result=$unused_jars_dir/by_class_"$current_time".txt
    >$unused_jars_result

    for file in $(find . -maxdepth 1 -type f -name \*.jar | sort); do
        jar_name=$(echo $file | awk -F '/' '{print $2}')

        check_jar_use $jar_name $find_in_class_dir_file 1
        [ $? == 1 ] && continue

        check_jar_use $jar_name $find_in_conf_dir_file 0
        [ $? == 1 ] && continue

        log_run "当前Jar包未被使用 $jar_name"
        echo $jar_name >>$unused_jars_result

        log_run "重命名文件 $jar_name -> $jar_name.unused"
        mv $jar_name "$jar_name".unused

        jar_dir="$jar_name"-dir
        log_run "重命名文件 $jar_dir -> $jar_dir.unused"
        mv $jar_dir "$jar_dir".unused
    done
}

outer_loop() {
    while (true); do
        current_time=$(date +%Y%m%d-%H%M%S)
        find_in_class_dir_file="$find_in_dir"/find_in_class_dir-"$current_time".txt
        run_log_file=$run_log_dir/run-"$current_time".log
        >$run_log_file

        log_run "$(date)"

        cat $classes_dir_file | sort | uniq | sort | awk '{if(length($0)>0){print $0}}' >$find_in_class_dir_file

        find . -maxdepth 1 -type d -name \*.jar-dir | sort >>$find_in_class_dir_file

        next_round

        log_run "$(date)"

        num=$(head -1 $unused_jars_result | wc -l)
        [ $num -eq 0 ] && break
    done
}

rm_empty_txt_in_dir() {
    dir=$1

    [ ! -d $dir ] && return

    log_run "删除目录中为空的.txt文件 $dir"

    for file in $(find $dir -maxdepth 1 -type f -name \*.txt -size 0c); do
        log_run "删除空的.txt文件 $file"
        rm -f $file
    done
}

if [ ! -f $classes_dir_file ]; then
    echo "文件不存在 $classes_dir_file"
    exit
fi

num=$(head -1 $classes_dir_file | wc -l)
if [ $num -eq 0 ]; then
    echo "请在 $classes_dir_file 文件中写入Java项目的classes目录"
    exit
fi

[ -d $classes_info_dir ] || mkdir $classes_info_dir
[ -d $used_jars_by_class_dir ] || mkdir $used_jars_by_class_dir
[ -d $unused_jars_dir ] || mkdir $unused_jars_dir
[ -d $find_in_dir ] || mkdir $find_in_dir
[ -d $run_log_dir ] || mkdir $run_log_dir

if [ "$find_rows" != "" ]; then
    if [[ ! "$find_rows" =~ ^[1-9]+[0-9]*$ ]]; then
        echo "输入的参数非法，不是整数 $find_rows"
        exit 1
    fi
    check_rows=$find_rows
fi

log_run "check_rows: $check_rows"

>$run_log_file

log_run "$(date)"

unzip_jars

gen_classes_info

cat $config_dir_file | sort | uniq | sort | awk '{if(length($0)>0){print $0}}' >$find_in_conf_dir_file

outer_loop

rm_empty_txt_in_dir $used_jars_by_class_dir
rm_empty_txt_in_dir $unused_jars_dir

log_run "$(date)"

echo "[执行结束]"
echo "保存各Jar包中类名信息目录: $classes_info_dir"
echo "保存通过类名查找有被使用的Jar包信息目录: $used_jars_by_class_dir"
echo "保存未被使用的Jar包信息目录: $unused_jars_dir"
