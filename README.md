# docker-delete

 Usage:
 docker-delete -sr                                   [description: show all image repositories]
 docker-delete -st <image repository>                [description: show all tags of specified image repository]
 docker-delete -dr <image repository>                [description: delete specified image repository ]
 docker-delete -dr -all                              [description: delete all image repositories ]
 docker-delete -dt <image repository> <image tag>    [description: delete specified tag of specified image repository ]
 docker-delete -dt <image repository>                [description: delete all tags of specified image repository ]
 docker-delete -keep <N>                             [description: keep last N tags for all repositories]
 docker-delete -keep-repo <repo> <N>                 [description: keep last N tags for specified repository]
