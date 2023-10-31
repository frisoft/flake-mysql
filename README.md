# Run mysql server

```
nix run
```

From Github

`nix run github:frisoft/flake-mysql`

# Stop the server

You need just to close the nix-shell

```
nix run .#stop
```

From Github

`nix run github:frisoft/flake-mysql#stop`

# Reset the DB

Before starting the server:

```
rm -rf mysql
```


# Logs

`cat mysql/mysql.log`


