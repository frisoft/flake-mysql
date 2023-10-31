{
  description = "mysql server";

  inputs = {
    nixpkgs.url = "nixpkgs"; # Resolves to github:NixOS/nixpkgs
    # Helpers for system-specific outputs
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    # Create system-specific outputs for the standard Nix systems
    # https://github.com/numtide/flake-utils/blob/master/default.nix#L3-L9
    flake-utils.lib.eachDefaultSystem (system:
      let
      	pkgs = import nixpkgs { inherit system; };
        mysql = pkgs.mysql80;
      in
      {
        # A simple executable package
        # packages.default = pkgs.writeScriptBin "mysqlserver" ''
        apps.default = let
          serv = pkgs.writeShellApplication {
            name = "mysqlserver";
            runtimeInputs = [mysql];
            text = ''
              echo "I am currently being run!"
              MYSQL_BASEDIR=${mysql}
              MYSQL_HOME=$PWD/mysql
              MYSQL_DATADIR=$MYSQL_HOME/data
              export MYSQL_UNIX_PORT=$MYSQL_HOME/mysql.sock
              MYSQL_PID_FILE=$MYSQL_HOME/mysql.pid
              alias mysql='mysql -u root'

              if [ ! -d "$MYSQL_HOME" ]; then
                # Make sure to use normal authentication method otherwise we can only
                # connect with unix account. But users do not actually exists in nix.
                # mysql_install_db \
                #   --auth-root-authentication-method=normal \
                #   --datadir=$MYSQL_DATADIR --basedir=$MYSQL_BASEDIR \
                #   --pid-file=$MYSQL_PID_FILE
                echo "Initializing mysql database"
                which mysqld
                mkdir -p "$MYSQL_DATADIR"
                mysqld --initialize-insecure --basedir="$MYSQL_BASEDIR" --datadir="$MYSQL_DATADIR"
              fi

              # Starts the daemon
              mysqld --datadir="$MYSQL_DATADIR" --pid-file="$MYSQL_PID_FILE" \
                --socket="$MYSQL_UNIX_PORT" 2> "$MYSQL_HOME"/mysql.log &
              MYSQL_PID=$!
              echo "Started mysql with pid $MYSQL_PID"
            '';
          };
        in {
          type = "app";
          program = "${serv}/bin/mysqlserver";
        };

        apps.stop = let
          serv = pkgs.writeShellApplication {
            name = "mysqlstop";
            runtimeInputs = [mysql];
            text = ''
              echo "Stopping Mysql..."
              MYSQL_HOME="$PWD"/mysql
              export MYSQL_UNIX_PORT="$MYSQL_HOME"/mysql.sock
              mysqladmin -u root --socket="$MYSQL_UNIX_PORT" shutdown
            '';
          };
        in {
          type = "app";
          program = "${serv}/bin/mysqlstop";
        };
      });
}
