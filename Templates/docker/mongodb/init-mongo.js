db.createUser({
    user: "p-db-usr",
    pwd: "***",
    roles: [{
        role: "readWrite",
        db: "p-db"
    }]
});
