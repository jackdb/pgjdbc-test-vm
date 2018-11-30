# PGJDBC Test VM

### What is the PGJDBC Test VM?

A Vagrant configuration for spinning up a VM with *multiple* PostgreSQL installations for testing the [PostgreSQL JDBC driver](https://github.com/pgjdbc/pgjdbc).

### How do I use it?

Clone this repo.
Make sure you have [Vagrant](http://www.vagrantup.com/) installed. 

To startup the VM:

    $ vagrant up

The first time you start it up it will update the OS and install everything. This takes a couple of minutes. After that it does not do any updates on startup and should startup quickly.

To shutdown the VM:

    $ vagrant halt

To destroy the VM:

    $ vagrant destroy

### How do I connect to the version `X.Y` PostgreSQL server?

To get the IP address of the VM:
```sh
$ vagrant ssh
vagrant@ubuntu-bionic:~$ ifconfig
```

Note down the IP address. Make sure you can ping it from your host machine.

Once the VM is started the port forwarding will make it act like the PostgreSQL servers are installed on your desktop and available at the forwarded ports. If you have `psql` installed then just specify the port number for the server you'd like to connect to.

For example to connect to the "test" database on the 9.3 server as the user "test" (change the host IP address):

```
$ psql -h 172.28.128.3 -p 10093 test test
Password for user test: 
psql (9.1.9, server 9.3.0)
WARNING: psql version 9.1, server version 9.3.
         Some psql features might not work.
SSL connection (cipher: (NONE), bits: -1)
Type "help" for help.

test=>
```

Remember that the password for the "test" user is "test".

The bin/ directory contains a wrapper for psql that connects to the test database for a given PostgreSQL version:

```
$ bin/psql 10
psql (11.1 (Ubuntu 11.1-1.pgdg18.04+1), server 10.6 (Ubuntu 10.6-1.pgdg18.04+1))
SSL connection (protocol: TLSv1.2, cipher: ECDHE-RSA-AES256-GCM-SHA384, bits: 256, compression: off)
Type "help" for help.

test=> 
```

### How do I use it to test the JDBC driver?

1. Clone the [PostgreSQL JDBC driver](https://github.com/pgjdbc/pgjdbc).

2. Add a `build.local.properties` file and add
```
server=172.28.128.3
port=10011
```
Change the IP address, and port numbers to point to the version of PostgreSQL you want to test against (ex: 10010 for v10)

   **Note:** To test against a different version of PostgreSQL just change the port. For example using `10096` would test against version 9.6.

3. Build and test the JDBC driver using `mvn`:

   ```
   $ mvn clean compile test
   ```

To run the SSL related tests copy the file `ssltest.properties` to `ssltest.local.properties` and enable the SSL test property.

```
**Note:** The test VM uses the same SSL certificates in certdir as the pgjdbc repo.
```

### What does it do?

When it is first started up the VM:

1. Setups up a base VM with Ubuntu 18.04 
1. Adds the PostgreSQL Global Development Group (PGDG) [apt repo](http://wiki.postgresql.org/wiki/Apt)
1. Updates all packages
1. Installs postgresql-${PG_VERSION} and postgresql-contrib-${PG_VERSION}
1. Updates the `postgresql.conf` file to change `listen_address = '*'`
1. Updates `pg_hba.conf` to allow inbound connections required by pgjdbc tests.
1. Copies the SSL config files (`root.crt`, `server.crt`, and `server.key`)
1. Creates sample users and databases matching those used by pgjdbc.
1. Installs the `sslinfo` and `hstore` extensions (via `CREATE EXTENSION ...`)

This is done for each version of PostgreSQL that is installed (see next section for versions).

The Vagrantfile also sets up port forwarding for each PostgreSQL installation to your local machine.

### What versions of PostgreSQL does it install?

 * 9.3 - mapped to port `10093`
 * 9.4 - mapped to port `10094`
 * 9.5 - mapped to port `10095`
 * 9.6 - mapped to port `10096`
 * 10 - mapped to port `10010`
 * 11 - mapped to port `10011`

In general PostgreSQL version `X.Y` is mapped to port `100XY`.

The bootstrap script for the VM analyzes the available set of packages to determine which ones to install. The script itself should not need to be updated as new versions are released however the port forwarding would need to be updated to reflect them.

### What databases and users does it setup?

A test user (with name "test" and password "test") and the databases listed below are created for *each* PostgreSQL version that is installed. This matches up with the default configuration of the JDBC drivers `build.properties` and `build.xml` files.

The following databases are created (each is used somewhere in the JDBC driver tests):

1. test 
1. hostdb 
1. hostssldb 
1. hostnossldb 
1. hostsslcertdb 
1. certdb 

### Why did you make this?

I was adding some SSL related tests to the driver and getting an environment to test it was non-trivial. It seemed like a good idea to automate it.

VMs are great for testing and it makes it *much* easier for someone new to get involved in adding to a project.

### Why does the Vagrantfile share the entire project with the VM?

Or alternatively, why not just a sub directory?

This was all designed to eventually be merged into the JDBC driver project itself. The `certdir` directory is a clone of the same directory (at the same relative path) as the JDBC driver. This was done so that after this is merged in to the JDBC driver no code change is required to the JDBC driver tests (since the certs will still be in the same place).

### Why isn't this part of the driver project itself?

Hopefully it will be.

### Can I use this? What license is it?

Yes. See [LICENSE](LICENSE) for details.
