### What is it?

A Vagrant configuration for spinning up a VM with *multiple* PostgreSQL installations for testing the [PostgreSQL JDBC driver](https://github.com/pgjdbc/pgjdbc).

### How do I use it?

First make sure you have [Vagrant](http://www.vagrantup.com/) installed. 

To startup the VM:

    $ vagrant up

The first time you start it up it will update the OS and install everything. This takes a couple of minutes. After that it does not do any updates on startup and should startup quickly.

To shutdown the VM:

    $ vagrant halt

To destroy the VM:

    $ vagrant destroy

### What does it do?

When it is first started up the VM:

1. Setups up a base VM with Ubuntu 12.04 
1. Adds the PostgreSQL Global Development Group (PGDG) [apt repo](http://wiki.postgresql.org/wiki/Apt)
1. Updates all packages
1. Installs postgresql-${PG_VERSION} and postgresql-contrib-${PG_VERSION}
1. Updates the `postgresql.conf` file to change `listen_address = '*'`
1. Updates `pg_hba.conf`
1. Copies the SSL config files (`root.crt`, `server.crt`, and `server.key`)
1. Creates sample users and databases
1. Installs the `sslinfo` extension (either via `CREATE EXTENSION ...` or manually for earlier versions)

This is done for each version of PostgreSQL that is installed (see next section for versions).

The Vagrantfile also sets up port forwarding for each PostgreSQL installation to your local machine.

### What versions of PostgreSQL does it install?

 * 8.4 - mapped to port `10084`
 * 9.0 - mapped to port `10090`
 * 9.1 - mapped to port `10091`
 * 9.2 - mapped to port `10092`
 * 9.3 - mapped to port `10093`

In general PostgreSQL version `X.Y` is mapped to port `100XY`.

### What databases and users does it setup?

A test user (with name "test" and password "test") and the databases listed below are created for *each* PosgreSQL version that is installed. This matches up with the default configuration of the JDBC drivers `build.properties` and `build.xml` files.

The following databases are created (each is used somewhere in the JDBC driver tests):

1. test 
1. hostdb 
1. hostssldb 
1. hostnossldb 
1. hostsslcertdb 
1. certdb 

### How do I connect to the version `X.Y` PostgreSQL server?

Once the VM is started it the port forwarding will make it act like the PostgreSQL servers are installed on your desktop and available at the forwarded ports. If you have `psql` installed then just specify the port number for the server you'd like to connect to.

For example to connect to the "test" database on the 8.4 server as the user "test":

    $ psql -h localhost -p 10084 test test
    Password for user test: 
    psql (9.1.9, server 8.4.17)
    WARNING: psql version 9.1, server version 8.4.
             Some psql features might not work.
    SSL connection (cipher: (NONE), bits: -1)
    Type "help" for help.
    
    test=> 

Or for example to connect to the "hostssldb" database on the 9.3 server as the user "test":

    $ psql -h localhost -p 10093 hostssldb test
    Password for user test: 
    psql (9.1.9, server 9.3.0)
    WARNING: psql version 9.1, server version 9.3.
             Some psql features might not work.
    SSL connection (cipher: (NONE), bits: -1)
    Type "help" for help.
    
    hostssldb=>

Remeber that the password for the "test" user is "test".

### How do I use it to test the JDBC driver?

1. Clone this repo
1. Spin up the VM (see above)
1. Clone the [PostgreSQL JDBC driver](https://github.com/pgjdbc/pgjdbc).
1. Edit the file `build.properties` and change `def_pgport=10093`

    **Note:** To test against a different version of PostgreSQL just change the port. For example using `10084` would test against version 8.4.

1. Build and test the JDBC driver using `ant`:

        $ ant test

To run the SSL related tests edit the file `ssltest.properties`:

1. Uncomment the SSL JDBC urls you'd like to test
1. Update the port for the server you want to test (ex: use 10084 for the 8.4 server, 10093 for the 9.3 server, etc).

The resulting file will look something like this (example for version 8.4):

    sslhostnossl8=jdbc:postgresql://localhost:10084/hostnossldb?sslpassword=sslpwd
    sslhostnossl8prefix=
      
    sslhostgh8=jdbc:postgresql://localhost:10084/hostdb?sslpassword=sslpwd
    sslhostgh8prefix=
    sslhostbh8=jdbc:postgresql://127.0.0.1:10084/hostdb?sslpassword=sslpwd
    sslhostbh8prefix=
    
    sslhostsslgh8=jdbc:postgresql://localhost:10084/hostssldb?sslpassword=sslpwd
    sslhostsslgh8prefix=
    sslhostsslbh8=jdbc:postgresql://127.0.0.1:10084/hostssldb?sslpassword=sslpwd
    sslhostsslbh8prefix=
    
    sslhostsslcertgh8=jdbc:postgresql://localhost:10084/hostsslcertdb?sslpassword=sslpwd
    sslhostsslcertgh8prefix=
    sslhostsslcertbh8=jdbc:postgresql://127.0.0.1:10084/hostsslcertdb?sslpassword=sslpwd
    sslhostsslcertbh8prefix=
    
    sslcertgh8=jdbc:postgresql://localhost:10084/certdb?sslpassword=sslpwd
    sslcertgh8prefix=
    sslcertbh8=jdbc:postgresql://127.0.0.1:10084/certdb?sslpassword=sslpwd

### Why did you make this?

I was adding some SSL related tests to the driver and getting an environment to test it was non-trivial. It seemed like a good idea to automate it.

VMs are great for testing and it makes it *much* easier for someone new to get involved in adding to a project.

### Why does the Vagrantfile share the entire project with the VM? (*e.g. why not just a sub directory*)?

This was all designed to eventually be merged into the JDBC driver project itself. The `certdir` directory is a clone of the same directory (at the same relative level) as the JDBC driver. This was done so that after this is merged in to the JDBC driver no code change is required to the JDBC driver tests (since the certs will still be in the same place).


### Why isn't this part of the driver project itself?

Hopefully it will be.
