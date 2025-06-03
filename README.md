# docker-delete

`docker-delete` 是一个用于管理和批量删除 Docker 镜像仓库及标签的命令行工具。

## 用法

```shell
docker-delete -sr
```
> 显示所有镜像仓库

```shell
docker-delete -st <image repository>
```
> 显示指定镜像仓库的所有标签

```shell
docker-delete -dr <image repository>
```
> 删除指定镜像仓库

```shell
docker-delete -dr -all
```
> 删除所有镜像仓库

```shell
docker-delete -dt <image repository> <image tag>
```
> 删除指定镜像仓库下的指定标签

```shell
docker-delete -dt <image repository>
```
> 删除指定镜像仓库下的所有标签

```shell
docker-delete -keep <N>
```
> 所有仓库只保留最新的 N 个标签，其余标签删除

```shell
docker-delete -keep-repo <repo> <N>
```
> 指定仓库只保留最新的 N 个标签，其余标签删除

---

## 说明

- 该工具适用于需要批量清理 Docker 镜像仓库和标签的场景。
- 请谨慎使用删除命令，避免误删重要镜像。

## License

MIT
