This is a drop-in replacement for rails' `secure_password` using scrypt.

To use, just copy the files into the appropriate directories:

-   [`config/initializers/secure_password.rb`]: Overrides bcrypt with scrypt

-   [`config/initializers/filter_parameter_logging.rb`]: Ugly patch to
    hide the digest from the SQL logs.

    ```sql
    D, [2019-01-01T12:00:00.000000 #00000] DEBUG -- : [00000000-0000-0000-0000-000000000000]   User Create (0.1ms)  INSERT INTO "users" ("email", "password_digest", "created_at", "updated_at") VALUES ($1, $2, $3, $4) RETURNING "id"  [["email", "user@example.com"], ["password_digest", "[FILTERED]"], ["created_at", "2019-01-01 12:00:00.000000"], ["updated_at", "2019-01-01 12:00:00.000000"]]
    D, [2019-01-01T12:00:00.000000 #00000] DEBUG -- : [00000000-0000-0000-0000-000000000000]    (0.1ms)  COMMIT
    ```

-   [`app/models/concerns/hidden_passwords.rb`]: Removes `password_digest`
from serialized output.  Include in the `User` model.

    For example:

    ```ruby
    irb(main):001:0> User.first
      User Load (0.1ms)  SELECT  "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT $1  [["LIMIT", 1]]
    => #<User id: 1, email: "user@example.com", created_at: "2019-01-01 12:00:00", updated_at: "2019-01-01 12:00:00">
    irb(main):002:0> User.first.inspect
      User Load (0.1ms)  SELECT  "users".* FROM "users" ORDER BY "users"."id" ASC LIMIT $1  [["LIMIT", 1]]
    => "#<User id: 1, email: \"user@example.com\", created_at: \"2019-01-01 12:00:00\", updated_at: \"2019-01-01 12:00:00\">"
    ```

In `Gemfile` replace the `bcrypt` gem with `scrypt`.

[`config/initializers/secure_password.rb`]: https://github.com/jlduran/secure_password/blob/master/config/initializers/secure_password.rb
[`config/initializers/filter_parameter_logging.rb`]: https://github.com/jlduran/secure_password/blob/master/config/initializers/filter_parameter_logging.rb
[`app/models/concerns/hidden_passwords.rb`]: https://github.com/jlduran/secure_password/blob/master/app/models/concerns/hidden_passwords.rb
