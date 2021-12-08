#https://github.com/twright-msft/mssql-node-docker-demo-app
#https://docs.microsoft.com/en-us/sql/linux/sql-server-linux-docker-container-configure?view=sql-server-ver15&pivots=cs1-bash

FROM mcr.microsoft.com/mssql/server:2019-latest

ENV TZ=America/New_York

ENV TZ=America/New_York


/usr/src/app/do-my-sql-commands.sh & /opt/mssql/bin/sqlservr