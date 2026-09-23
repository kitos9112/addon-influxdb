# InfluxDB 3 for Home Assistant

InfluxDB 3 is a time series database optimized for high-write-volume data such
as metrics, sensor data, and events. It exposes an HTTP API for client
interaction and is often used in combination with Grafana to visualize data.

This add-on includes the InfluxDB 3 Explorer UI for administration, querying,
and dashboards.

## Installation

1. In Home Assistant, open **Settings → Add-ons → Add-on Store → Repositories**.
1. Add `https://github.com/kitos9112/addon-influxdb` and refresh the store.
1. Select **InfluxDB 3**, install it, then start it.
1. Check the add-on logs, then select **Open Web UI**.

Home Assistant builds this add-on's container on your own machine; no prebuilt
image is published by this repository. Installation and updates take longer
and use more CPU, disk space, and disk writes than downloading a prebuilt
image. The build needs network access to upstream image registries and package
repositories. If it fails, check the build log for an unavailable upstream
dependency before starting the add-on.

## Migrating an existing local or community add-on

This repository's add-on is a separate installation. Home Assistant assigns
different IDs and `/data` volumes to `local_influxdb`, the former community
add-on, and this repository's add-on. Installing it will not replace your old
instance or transfer its data automatically.

Before switching, make a full Home Assistant backup that includes the old
add-on's data. Save its configuration, InfluxDB token, and any integration
settings. Stop writers and the old add-on; restore the old add-on's
`/data/influxdb3` and `/data/explorer` data into the new add-on's corresponding
volume using a supported Home Assistant backup/restore or copy procedure.
Then start the new add-on, check its logs and Explorer, and update integrations
to its new hostname. Do not uninstall the old add-on until the new installation
has been verified. Never run both add-ons against the same data directory.

InfluxDB 1.x and 2.x data cannot be copied directly into InfluxDB 3; use the
appropriate export/migration path instead.

## Upgrading to InfluxDB 3.11

InfluxDB 3.10 and later migrate the on-disk catalog to a new format during
the first startup. The migration is automatic, but it is one-way: InfluxDB
3.9 and earlier cannot read the migrated catalog.

Before upgrading from an add-on release that contains InfluxDB 3.9 or
earlier, create a full Home Assistant backup that includes this add-on's data.
Do not interrupt the first startup after upgrading. Keep the backup until you
have confirmed that InfluxDB and the Explorer UI both work with your data.

## Configuration

**Note**: _Remember to restart the add-on when the configuration is changed._

Example add-on configuration:

```yaml
log_level: info
auth: true
ssl: true
certfile: fullchain.pem
keyfile: privkey.pem
edition: core
license_type: home
default_database: homeassistant
default_write_api: v1
```

**Note**: _This is just an example, don't copy and paste it! Create your own!_

### Option: `log_level`

The `log_level` option controls the level of log output by the addon and can
be changed to be more or less verbose, which might be useful when you are
dealing with an unknown issue. Possible values are:

- `trace`: Show every detail, like all called internal functions.
- `debug`: Shows detailed debug information.
- `info`: Normal (usually) interesting events.
- `warning`: Exceptional occurrences that are not errors.
- `error`: Runtime errors that do not require immediate action.
- `fatal`: Something went terribly wrong. Add-on becomes unusable.

Please note that each level automatically includes log messages from a
more severe level, e.g., `debug` also shows `info` messages. By default,
the `log_level` is set to `info`, which is the recommended setting unless
you are troubleshooting.

### Option: `auth`

Enable or disable InfluxDB user authentication.

**Note**: _Turning this off is NOT recommended!_

### Option: `edition`

Selects the InfluxDB 3 edition to run: `core` or `enterprise`. If you provide
`license_email` or `license_file`, the add-on will automatically use
Enterprise.

### Option: `license_email`

Email address used for Enterprise license verification. Used together with
`license_type`.

To generate a **home** license, set `license_email` and `license_type: home`
in the add-on configuration. On first Enterprise start, InfluxDB will send a
verification email; once verified, the license is generated and stored.

### Option: `license_file`

Path to a license file (for Enterprise). When provided, it overrides
`license_email` and `license_type`.

### Option: `license_type`

License type for Enterprise: `home`, `trial`, or `commercial`.

### Option: `admin_token`

Optional admin token. If omitted, the add-on generates a token during first
startup and stores it in `/data/influxdb3/admin-token.json`.

### Option: `default_database`

The database to create on startup (default: `homeassistant`).

### Option: `default_write_api`

The default compatibility API to document for writes: `v1` or `v2`.
This add-on defaults to `v1`.

### Option: `node_id`

The InfluxDB node identifier (default: `ha-node`).

### Option: `cluster_id`

Enterprise cluster identifier (default: `ha-cluster`).

### Option: `ssl`

Enables/Disables SSL (HTTPS) on the web interface.
Set it `true` to enable it, `false` otherwise.

**Note**: _This does NOT activate SSL for InfluxDB, just the web interface_

### Option: `certfile`

The certificate file to use for SSL.

**Note**: _The file MUST be stored in `/ssl/`, which is the default_

### Option: `keyfile`

The private key file to use for SSL.

**Note**: _The file MUST be stored in `/ssl/`, which is the default_

### Option: `leave_front_door_open`

Adding this option to the add-on configuration allows you to disable
authentication on the Web Terminal by setting it to `true` and leaving the
username and password empty.

**Note**: _We STRONGLY suggest, not to use this, even if this add-on is
only exposed to your internal network. USE AT YOUR OWN RISK!_

## Integrating into Home Assistant

The `influxdb` integration of Home Assistant makes it possible to transfer all
state changes to an InfluxDB database.

You need to do the following steps in order to get this working:

- Click on "OPEN WEB UI" to open the InfluxDB 3 Explorer UI.
- Ensure the default database (e.g., `homeassistant`) exists.
- Copy the admin token from `/data/influxdb3/admin-token.json` or set your
  own `admin_token` in the add-on configuration.

Now we've got this in place, add the following snippet to your Home Assistant
`configuration.yaml` file.

```yaml
influxdb:
  host: <new-add-on-hostname>
  port: 8181
  database: homeassistant
  username: homeassistant
  password: <admin_token>
  max_retries: 3
  default_measurement: state
```

Restart Home Assistant.

Replace `<new-add-on-hostname>` with the hostname displayed by Home Assistant
for this repository's installed add-on; it is not the old `local_influxdb` or
`a0d7b954-influxdb` hostname.

You should now see the data flowing into InfluxDB by visiting the web-interface
and using the Data Explorer.

**Note**: The v1 compatibility API uses the token as the password and ignores
the username.

If you prefer the v2 compatibility API, use `/api/v2/write` with the admin
token in the `Authorization: Token ...` header and set `default_write_api` to
`v2` in the add-on configuration.

Full details of the Home Assistant integration can be found here:

<https://www.home-assistant.io/integrations/influxdb/>

## Known issues and limitations

- The add-on only configures SSL for the Explorer UI (via NGINX). The InfluxDB
  HTTP API itself does not enable TLS by default.

## Changelog & Releases

This repository keeps a change log using [GitHub's releases][releases]
functionality.

Releases are based on [Semantic Versioning][semver], and use the format
of `MAJOR.MINOR.PATCH`. In a nutshell, the version will be incremented
based on the following:

- `MAJOR`: Incompatible or major changes.
- `MINOR`: Backwards-compatible new features and enhancements.
- `PATCH`: Backwards-compatible bugfixes and package updates.

## Support and license

For add-on support, open an
[issue](https://github.com/kitos9112/addon-influxdb/issues). For private
vulnerability reports, use the repository's
[security policy](../.github/SECURITY.md). The add-on source is MIT-licensed; see
[LICENSE.md](../LICENSE.md) for the original and current attributions. InfluxDB
3 and Explorer have separate upstream licenses; the repository's MIT license
does not cover their binaries or UI assets.
Review the upstream terms before installing, including the Enterprise
[At-Home license](https://www.influxdata.com/legal/influxdata-end-user-software-license-agreement/)
and Explorer's `/app-root/license.txt` in its upstream container image.

[releases]: https://github.com/kitos9112/addon-influxdb/releases
[semver]: https://semver.org/spec/v2.0.0.html
