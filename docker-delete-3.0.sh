#!/bin/bash

Container_Registry_Name=${Container_Registry_Name:-local_registry}
DOCKER_REGISTRY_DIR=$(docker inspect "$Container_Registry_Name" --format '{{ range .Mounts }}{{ if eq .Destination "/var/lib/registry" }}{{ .Source }}{{ end }}{{ end }}')
DOCKER_REGISTRY_CONTAINER_ID=$(docker ps -q --filter "name=^/${Container_Registry_Name}$")

repositories_dir=$DOCKER_REGISTRY_DIR/docker/registry/v2/repositories
blobs_dir=$DOCKER_REGISTRY_DIR/docker/registry/v2/blobs/sha256/


function checkConfiguration(){
    pass="true"
if [ -z "$Container_Registry_Name" ]; then
    echo "Error: Container_Registry_Name is not set. Please specify a registry container name."
    exit 1
fi
    if [ ! "$DOCKER_REGISTRY_CONTAINER_ID" ]; then
        echo -e "\033[31;1m Please set the env variable 'DOCKER_REGISTRY_CONTAINER_ID'.\033[0m"
        pass="false"
    else
        containerNum=$(docker ps | awk '{print $1}' | grep "$DOCKER_REGISTRY_CONTAINER_ID" |awk 'END{print NR}')
        if [ $containerNum == '0' ]; then
            echo -e "\033[31;1m No such running container : '$DOCKER_REGISTRY_CONTAINER_ID'.\033[0m"
            echo -e "\033[31;1m Please check that the env variable 'DOCKER_REGISTRY_CONTAINER_ID' is correct.\033[0m"
            pass="false"
        else
            registryContainerNum=$(docker ps | awk '{print $1,$2}' | grep "$DOCKER_REGISTRY_CONTAINER_ID" | grep "registry" |awk 'END{print NR}')
            if [ $registryContainerNum == '0' ]; then
                echo -e "\033[31;1m The container : '$DOCKER_REGISTRY_CONTAINER_ID' is running ,but it is not a Docker Registry containser.\033[0m"
                echo -e "\033[31;1m Please check that the env variable 'DOCKER_REGISTRY_CONTAINER_ID' is correct.\033[0m"
                pass="false"
            fi
        fi
    fi

    if [ ! "$DOCKER_REGISTRY_DIR" ]; then
        echo -e "\033[31;1m Please set the env variable 'DOCKER_REGISTRY_DIR'.\033[0m"
        pass="false"
    else
        if [ ! -d "$repositories_dir" ]; then
            echo -e "\033[31;1m '$DOCKER_REGISTRY_DIR' is not a Docker Registry dir.\033[0m"
            echo -e "\033[31;1m Please check that the env variable 'DOCKER_REGISTRY_DIR' is correct.\033[0m"
            pass="false"
        fi
    fi

    if [ $pass == "false" ]; then
        exit 2
    fi
}

function deleteBlobs(){
    docker exec -it $DOCKER_REGISTRY_CONTAINER_ID  sh -c ' registry garbage-collect /etc/docker/registry/config.yml'

    emptyPackage=$(find $blobs_dir -type d -empty)

    if [ "$emptyPackage" ]; then
        find $blobs_dir -type d -empty | xargs -n 1 rm -rf

        restartRegistry=$(docker restart $DOCKER_REGISTRY_CONTAINER_ID)
        if [ $restartRegistry == "$DOCKER_REGISTRY_CONTAINER_ID"  ]; then
            echo -e "\033[32;1m Successful restart of registry container\033[0m"
        fi
        echo -e "\033[32;1m Successful deletion of blobs\033[0m"
    fi
}

function showHelp(){
    echo -e "\033[31;1m Usage: \033[0m"
    echo -e "\033[31;1m docker-delete -sr                                   [description: show all image repositories] \033[0m"
    echo -e "\033[31;1m docker-delete -st <image repository>                [description: show all tags of specified image repository] \033[0m"
    echo -e "\033[31;1m docker-delete -dr <image repository>                [description: delete specified image repository ] \033[0m"
    echo -e "\033[31;1m docker-delete -dr -all                              [description: delete all image repositories ]"
    echo -e "\033[31;1m docker-delete -dt <image repository> <image tag>    [description: delete specified tag of specified image repository ] \033[0m"
    echo -e "\033[31;1m docker-delete -dt <image repository>                [description: delete all tags of specified image repository ] \033[0m"
    echo -e "\033[31;1m docker-delete -keep <N>                             [description: keep last N tags for all repositories] \033[0m"
    echo -e "\033[31;1m docker-delete -keep-repo <repo> <N>                 [description: keep last N tags for specified repository] \033[0m"
}

function checkRepositoryExist(){
    repository_dir=$repositories_dir/$1
    if [ ! -d "$repository_dir" ];then
        echo -e "\033[31;1m no such image repository : $1 .\033[0m"
        echo -e "\033[31;1m you can use 'docker-delete -sr' to show all repositories.\033[0m"
        exit 2
    fi
}

function checkTagExist(){
    tag_dir=$repositories_dir/$1/_manifests/tags/$2
    if [ ! -d "$tag_dir" ];then
        echo -e "\033[31;1m no such image tag : '$2' under $1 .\033[0m"
        echo -e "\033[31;1m you can  use 'docker-delete -st $1' to  show all tags of $1 .\033[0m"
        exit 2
    fi
}

function keepRecentTags(){
    keep_count=$1
    if ! [[ "$keep_count" =~ ^[0-9]+$ ]]; then
        echo -e "\033[31;1m Error: Keep count must be a positive integer.\033[0m"
        exit 2
    fi

    echo -e "\033[32;1m Keeping last $keep_count tags for all repositories...\033[0m"

    repositories=$(find "$repositories_dir" -name "_manifests" -exec dirname {} \; | sed "s|$repositories_dir/||g")

    for repo in $repositories; do
        echo -e "\033[34;1mProcessing repository: $repo\033[0m"

        tags_dir="$repositories_dir/$repo/_manifests/tags"
        if [ -d "$tags_dir" ]; then
            tags=$(ls -t $tags_dir)
            total_tags=$(echo "$tags" | wc -w)

            if [ $total_tags -gt $keep_count ]; then
                delete_count=$((total_tags - keep_count))
                tags_to_delete=$(echo "$tags" | tail -n $delete_count)

                for tag in $tags_to_delete; do
                    echo -e "  Deleting old tag: $tag"
                    checkTagExist "$repo" "$tag"

                    digest=$(ls $tags_dir/$tag/index/sha256 2>/dev/null)
                    if [ -n "$digest" ]; then
                        digestNum=$(find $repositories_dir/*/_manifests/tags -type d -name "$digest" | awk 'END{print NR}')
                        if [ "$digestNum" == '1' ]; then
                            rm -rf "$repositories_dir/$repo/_manifests/revisions/sha256/$digest"
                        fi
                    fi
                    rm -rf "$tags_dir/$tag"
                done
                                deleteBlobs
                                echo -e "\033[32;1m Finished keeping last $keep_count tags for all repositories.\033[0m"
            else
                echo -e "\033[33m Repository $repo has only $total_tags tags (≤ $keep_count), no need to delete.\033[0m"
            fi
        fi
    done

}

function keepRecentTagsForRepo(){
    repo=$1
    keep_count=$2

    if ! [[ "$keep_count" =~ ^[0-9]+$ ]]; then
        echo -e "\033[31;1m Error: Keep count must be a positive integer.\033[0m"
        exit 2
    fi
    checkRepositoryExist "$repo"

    echo -e "\033[32;1m Keeping last $keep_count tags for repository: $repo...\033[0m"

    tags_dir="$repositories_dir/$repo/_manifests/tags"
    if [ -d "$tags_dir" ]; then
        tags=$(ls -t $tags_dir)
        total_tags=$(echo "$tags" | wc -w)

        if [ $total_tags -gt $keep_count ]; then
            delete_count=$((total_tags - keep_count))
            tags_to_delete=$(echo "$tags" | tail -n $delete_count)

            for tag in $tags_to_delete; do
                echo -e "  Deleting old tag: $tag"
                checkTagExist "$repo" "$tag"

                digest=$(ls $tags_dir/$tag/index/sha256 2>/dev/null)
                if [ -n "$digest" ]; then
                    digestNum=$(find $repositories_dir/*/_manifests/tags -type d -name "$digest" | awk 'END{print NR}')
                    if [ "$digestNum" == '1' ]; then
                        rm -rf "$repositories_dir/$repo/_manifests/revisions/sha256/$digest"
                    fi
                fi
                rm -rf "$tags_dir/$tag"
            done
                        deleteBlobs
                        echo -e "\033[32;1m Finished keeping last $keep_count tags for repository: $repo.\033[0m"
        else
            echo -e "\033[33m Repository $repo has only $total_tags tags (≤ $keep_count), no need to delete.\033[0m"
        fi
    fi
}

checkConfiguration

if [ ! -n "$1" ];then
    showHelp
else
    case "$1" in
        -sr)
            cd $repositories_dir
            repositories=$(find . -name "_manifests" | cut -b 3-)
            if [ ! "$repositories" ];then
                echo -e "\033[31;1m No image repository existence.\033[0m"
            fi
            echo -e "\033[34;1m${repositories//\/_manifests/}\033[0m"
            ;;
        -st)
            if [ ! $2 ]; then
                echo -e "\033[31;1m use ‘docker-delete -st <image repository>' to show all tags of specified repository.\033[0m"
                exit 2
            fi
            checkRepositoryExist "$2"
            tags=$(ls $repositories_dir/$2/_manifests/tags)
            if [ ! "$tags" ]; then
                echo -e "\033[31;1m No tag under $2 .\033[0m"
            fi
            echo -e "\033[34;1m$tags\033[0m"
            ;;
        -dr)
            if [ ! $2 ]; then
                echo -e "\033[31;1m use ‘docker-delete -dr <image repository>' to delete specified repository\033[0m"
                echo -e "\033[31;1m or ‘docker-delete -dr -all’ to delele all repositories.\033[0m"
                exit 2
            fi
            if [ $2 == '-all' ]; then
                rm -rf $repositories_dir/*
                deleteBlobs
                echo -e "\033[32;1m Successful deletion of all image repositories.\033[0m"
                exit 0
            fi
            checkRepositoryExist "$2"
            rm -rf $repositories_dir/$2
            emptyRepositoriesNum=1
            while [ $emptyRepositoriesNum != "0" ]
            do
                find $repositories_dir -type d -empty | grep -v "_manifests" | grep -v "_layers" | grep -v "_uploads" | xargs -n 1 rm -rf
                emptyRepositoriesNum=$(find $repositories_dir -type d -empty | grep -v "_manifests" | grep -v "_layers" | grep -v "_uploads" | awk 'END{print NR}')
            done
            deleteBlobs
            echo -e "\033[32;1m Successful deletion of image repository:\033[0m \033[34;1m$2.\033[0m"
            ;;
        -dt)
            if [ ! $2 ]; then
                echo  -e "\033[31;1m use ‘docker-delete -dt <image repository> <images tag>' to delete specified tag of specified repository  \033[0m"
                echo  -e "\033[31;1m or ‘docker-delete -dt <image repository>’ to delele all tags of specified repository.\033[0m"
                exit 2
            fi
            checkRepositoryExist "$2"
            tags_dir=$repositories_dir/$2/_manifests/tags
            sha256_dir=$repositories_dir/$2/_manifests/revisions/sha256
            if [ ! $3 ]; then
                read -p "do you want to delete all tags of '$2' ? ,please input yes or no : " yes
                if [ $yes == "yes" ];then
                    rm -rf $tags_dir/*
                    rm -rf $sha256_dir/*
                    deleteBlobs
                    echo -e "\033[32;1m Successful deletion of all tags under \033[0m \033[34;1m$2\033[0m"
                    exit 0
                else
                    exit 2
                fi
            fi
            checkTagExist "$2" "$3"
            digest=$(ls $tags_dir/$3/index/sha256)
            digestNum=$(find $repositories_dir/*/_manifests/tags -type d -name "$digest" | awk 'END{print NR}')
            if [ "$digestNum" == '1' ]; then
                rm -rf $sha256_dir/$digest
            fi
            rm -rf $tags_dir/$3
            tags=$(ls $tags_dir)
            if [ ! "$tags" ]; then
                rm -rf $sha256_dir/*
            fi
            deleteBlobs
            echo  -e "\033[32;1m Successful deletion of\033[0m \033[34;1m$2:$3\033[0m"
            ;;
        -keep)
            if [ -z "$2" ]; then
                echo -e "\033[31;1m Usage: docker-delete -keep <N>\033[0m"
                exit 2
            fi
            keepRecentTags "$2"
            ;;
        -keep-repo)
            if [ -z "$2" ] || [ -z "$3" ]; then
                echo -e "\033[31;1m Usage: docker-delete -keep-repo <repository> <N>\033[0m"
                exit 2
            fi
            keepRecentTagsForRepo "$2" "$3"
            ;;
        *)
            showHelp
            ;;
    esac
fi
