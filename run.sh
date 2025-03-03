docker run -d \
  -e BUGZILLA_DB_HOST=mysql-server \
  -e BUGZILLA_DB_NAME=bugzilla \
  -e BUGZILLA_DB_USER=bugzilla_user \
  -e BUGZILLA_DB_PASS=secure_password \
  -e BUGZILLA_ADMIN_EMAIL=admin@example.com \
  -e BUGZILLA_ADMIN_PASS=admin_password \
  -e BUGZILLA_ADMIN_REALNAME="Bugzilla Administrator" \
  -p 80:80 \
  --name bugzilla \
  bugzilla