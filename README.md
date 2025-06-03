# 🐳 docker-delete

一个可爱又实用的 Docker 镜像批量管理和删除工具！

## ✨ 功能用法

| 指令                                                    | 描述                            |
|---------------------------------------------------------|---------------------------------|
| `docker-delete -sr`                                     | 🗂️ 显示所有镜像仓库             |
| `docker-delete -st <image repository>`                  | 🏷️ 查看指定仓库所有标签         |
| `docker-delete -dr <image repository>`                  | 🗑️ 删除指定镜像仓库             |
| `docker-delete -dr -all`                                | 🚨 删除所有镜像仓库（危险操作） |
| `docker-delete -dt <image repository> <image tag>`      | 🔖 删除指定仓库下的指定标签      |
| `docker-delete -dt <image repository>`                  | 🧹 删除指定仓库下全部标签        |
| `docker-delete -keep <N>`                               | ⏳ 所有仓库仅保留最新 N 个标签   |
| `docker-delete -keep-repo <repo> <N>`                   | 💾 指定仓库仅保留最新 N 个标签   |

---

## 📝 示例

```shell
docker-delete -sr
docker-delete -st my-repo
docker-delete -dr my-repo
docker-delete -dr -all
docker-delete -dt my-repo v1.2.3
docker-delete -dt my-repo
docker-delete -keep 5
docker-delete -keep-repo my-repo 3
```

---

## 💡 说明

- 本工具适合批量清理 Docker Registry 镜像仓库及标签。
- ⚠️ 删除操作不可恢复，请务必谨慎使用！
- 建议先用 `-sr` 和 `-st` 查看信息再执行删除命令。

## 🧸 License

MIT
