### Create local MongoDB container with persistemnt volume

(requires Docker)

The container will use a Mongo database:
 - db name: `p-db`
 - db user: `p-db-usr`
 - db user pwd: `***` (replace the password placehoders with your own password in *docker-compose.yml* and *init-mong.js* files)

The host can connect to the DB using port `32143`.

Create a container running in background: 
``` cmd
docker-compose -f docker-compose.yml up -d
```

Check container exists:
``` cmd
docker ps
```

Connect using mongo shell:
``` cmd
mongo "mongodb://p-db-usr:***@127.0.0.1:32143/p-db"
```

Same connection string can be used from C# using the MongoDB C# driver. See this article for .NET Core C# example:
https://docs.microsoft.com/en-us/aspnet/core/tutorials/first-mongo-app?view=aspnetcore-3.1&tabs=visual-studio
